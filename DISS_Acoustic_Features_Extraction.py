import os
import pandas as pd
import parselmouth
import numpy as np
from textgrid import TextGrid

WAV_DIR = '/Users/santiarroniz/Library/Mobile Documents/com~apple~CloudDocs/Academia/RESEARCH/__DISS__/PhD ABD/DISS_ABD_RESULTS/DISS_ABD_RESULTS_PRODUCTION/AUDIOS_SEGMENTED'

def parse_label(label):
    parts = label.split('-')
    if len(parts) >= 9:
        return {
            'phoneme': parts[0],
            'word': parts[1],
            'previous': parts[2],
            'target': parts[3],
            'following': parts[4],
            'tonicity': parts[5],
            'position': parts[6],
            'sex': parts[8],
            'age': parts[9] if len(parts) > 9 else ''
        }
    return None

def extract_spectral_features(segment):
    """Extract additional spectral features"""
    try:
        spectrum = segment.to_spectrum()
        features = {
            'spectral_kurtosis': spectrum.get_kurtosis(),
            'spectral_skewness': spectrum.get_skewness()
        }
        spectrum_matrix = spectrum.get_matrix()
        freqs = spectrum.get_all_frequencies()
        if len(spectrum_matrix) > 0:
            slope, _ = np.polyfit(freqs, 20 * np.log10(np.abs(spectrum_matrix[0])), 1)
            features['spectral_tilt'] = slope
        else:
            features['spectral_tilt'] = 0
        sound_array = segment.values[0]
        zero_crossings = np.sum(np.diff(np.signbit(sound_array)))
        features['zero_crossing_rate'] = zero_crossings / len(sound_array)
        return features
    except Exception as e:
        return {
            'spectral_kurtosis': 0,
            'spectral_skewness': 0, 
            'spectral_tilt': 0,
            'zero_crossing_rate': 0
        }

def extract_formants(segment):
    """Extract formant measurements (using mid time only)"""
    try:
        formant = segment.to_formant_burg()
        mid_time = segment.duration / 2
        features = {}
        for i in range(1, 4):  # Get F1-F3
            formant_freq = formant.get_value_at_time(i, mid_time)
            features[f'F{i}'] = formant_freq if not np.isnan(formant_freq) else 0
        return features
    except Exception as e:
        return {'F1': 0, 'F2': 0, 'F3': 0}

def extract_temporal_dynamics(segment):
    """Extract features related to temporal changes"""
    try:
        intensity = segment.to_intensity()
        values = intensity.values[0]
        features = {
            'intensity_std': np.std(values),
            'intensity_range': np.ptp(values),
            'intensity_slope': np.polyfit(np.arange(len(values)), values, 1)[0]
        }
        pitch = segment.to_pitch()
        pitch_values = pitch.selected_array['frequency']
        valid_pitch = pitch_values[pitch_values > 0]
        features['pitch_std'] = np.std(valid_pitch) if len(valid_pitch) > 0 else 0
        features['voiced_fraction'] = len(valid_pitch) / len(pitch_values)
        return features
    except Exception as e:
        return {
            'intensity_std': 0,
            'intensity_range': 0,
            'intensity_slope': 0,
            'pitch_std': 0,
            'voiced_fraction': 0
        }
    
def get_intensity_value(intensity_tier, time):
    """Get intensity value from either IntervalTier or PointTier"""
    try:
        if hasattr(intensity_tier, 'get_interval_at_time'):
            interval = intensity_tier.get_interval_at_time(time)
            return interval.mark
        elif hasattr(intensity_tier, 'get_point_at_time'):
            point = intensity_tier.get_point_at_time(time)
            return point.mark
        else:
            for i in range(len(intensity_tier)):
                if abs(intensity_tier[i].time - time) < 0.001:
                    return intensity_tier[i].mark
        return '0'
    except:
        return '0'
    
def get_intensity_points(sound, intensity_tier, start_time, end_time):
    """Get p1, v, p2 intensity values from a segment"""
    try:
        mid_time = (start_time + end_time) / 2
        p1_val = v_val = p2_val = None
        intensity = sound.to_intensity()
        for point in intensity_tier.points:
            point_time = point.time
            mark = point.mark
            if mark == "p1" and abs(point_time - start_time) < 0.2:
                p1_val = intensity.get_value(point_time)
            elif mark == "v" and abs(point_time - mid_time) < 0.2:
                v_val = intensity.get_value(point_time)
            elif mark == "p2" and abs(point_time - end_time) < 0.2:
                p2_val = intensity.get_value(point_time)
        return p1_val, v_val, p2_val
    except Exception as e:
        print(f"Error getting intensity points: {e}")
        return None, None, None

def calculate_intensity_ratios(p1, v, p2):
    """Calculate different intensity ratio measurements"""
    ratios = {}
    if all(x is not None for x in [p1, v, p2]):
        ratios['mean_intensity_ratio'] = v / ((p1 + p2) / 2)
        ratios['p1_valley_ratio'] = v / p1
        ratios['p2_valley_ratio'] = v / p2
        ratios['mean_log_ratio'] = 20 * np.log10(v / ((p1 + p2) / 2))
        ratios['rms_ratio'] = v / np.sqrt((p1**2 + p2**2) / 2)
        ratios['max_contrast'] = v / min(p1, p2)
    else:
        for key in ['mean_intensity_ratio', 'p1_valley_ratio', 'p2_valley_ratio', 
                    'mean_log_ratio', 'rms_ratio', 'max_contrast']:
            ratios[key] = 0
    return ratios

def extract_formants_trajectory(segment):
    """Extract formant measurements using time points defined as fractions of duration.
       Uses time fractions that avoid the very beginning and end to mitigate boundary issues."""
    try:
        duration = segment.duration
        if duration < 0.015 or duration > 0.130:
            print("Skipping segment (out of range: <15ms or >130ms)")
            return {f'F{i}_{pos}': 0 for i in range(1, 4) for pos in ['start', 'mid', 'end']}
        
        # Instead of 25% and 75%, use fractions that are farther from the boundaries.
        if duration >= 0.045:
            start_time = duration * 0.33  # 33% into the segment
            mid_time   = duration * 0.50  # 50% into the segment
            end_time   = duration * 0.67  # 67% into the segment
        else:
            start_time = 0.0
            mid_time   = duration / 2.0
            end_time   = duration

        print(f"Segment duration: {duration:.3f}s, start_time: {start_time:.3f}, mid_time: {mid_time:.3f}, end_time: {end_time:.3f}")
        
        # Create the formant object with high resolution.
        formant = segment.to_formant_burg(time_step=0.001, max_number_of_formants=5, maximum_formant=5500)
        
        # Debug: print formant values at defined time points.
        for i in range(1, 4):
            f_start = formant.get_value_at_time(i, start_time)
            f_mid = formant.get_value_at_time(i, mid_time)
            f_end = formant.get_value_at_time(i, end_time)
            print(f"F{i}: start={f_start:.2f}, mid={f_mid:.2f}, end={f_end:.2f}")
        
        time_points = {'start': start_time, 'mid': mid_time, 'end': end_time}
        features = {}
        for i in range(1, 4):  # For F1, F2, F3
            for pos, t in time_points.items():
                formant_freq = formant.get_value_at_time(i, t)
                if np.isnan(formant_freq) or formant_freq <= 0:
                    formant_freq = np.nan
                elif (i == 1 and not (150 <= formant_freq <= 1000)) or \
                     (i == 2 and not (500 <= formant_freq <= 2500)) or \
                     (i == 3 and not (1500 <= formant_freq <= 3500)):
                    formant_freq = 0
                features[f'F{i}_{pos}'] = formant_freq
        
        # If any value is NaN but others are valid, replace NaN with the mean of valid values.
        for i in range(1, 4):
            values = [features[f'F{i}_{pos}'] for pos in time_points.keys()]
            valid_values = [v for v in values if v is not None and not np.isnan(v) and v > 0]
            if valid_values:
                mean_value = np.mean(valid_values)
                for pos in time_points.keys():
                    if np.isnan(features[f'F{i}_{pos}']):
                        features[f'F{i}_{pos}'] = mean_value
            else:
                for pos in time_points.keys():
                    features[f'F{i}_{pos}'] = 0
        
        return features
    except Exception as e:
        print(f"Formant extraction error: {e}")
        return {f'F{i}_{pos}': 0 for i in range(1, 4) for pos in ['start', 'mid', 'end']}

def extract_features(sound, interval):
    """Extract features with progressive reliability"""
    start = interval.minTime
    end = interval.maxTime
    duration = end - start
    # Extract segment WITHOUT preserve_times (time axis resets to 0)
    segment = sound.extract_part(from_time=start, to_time=end)
    
    try:
        features = {'duration': duration}
        window_length = min(0.015, duration / 3)
        time_step = min(0.005, window_length / 4)
        min_pitch = max(50, 1 / duration * 5)
        
        try:
            intensity = segment.to_intensity(minimum_pitch=min_pitch, time_step=time_step)
            features.update({
                'mean_intensity': intensity.get_average(),
                'max_intensity': intensity.get_maximum(),
                'min_intensity': intensity.get_minimum()
            })
        except:
            features.update({
                'mean_intensity': 0,
                'max_intensity': 0,
                'min_intensity': 0
            })
            
        spectrum = segment.to_spectrum()
        features.update({
            'spectral_centroid': spectrum.get_center_of_gravity(),
            'spectral_spread': spectrum.get_standard_deviation()
        })
        
        samples = segment.values[0]
        zc_count = np.sum(np.abs(np.diff(np.signbit(samples))))
        zc_ratio = zc_count / duration if duration > 0 else 0
        features['z_crossings'] = int(zc_count)
        features['z_crossings_ratio'] = zc_ratio

        if duration >= 0.02:
            try:
                hnr = segment.to_harmonicity(time_step=time_step, minimum_pitch=min_pitch,
                                             silence_threshold=0.1, periods_per_window=2.0)
                hnr_data = np.array(hnr.values)
                valid_hnr = hnr_data[~np.isnan(hnr_data)]
                
                pitch = segment.to_pitch(time_step=time_step, pitch_floor=min_pitch, pitch_ceiling=400.0)
                pitch_data = pitch.selected_array['frequency']
                valid_pitch = pitch_data[pitch_data != 0]
                
                features.update({
                    'mean_hnr': float(np.mean(valid_hnr)) if len(valid_hnr) > 0 else 0,
                    'min_hnr': float(np.min(valid_hnr)) if len(valid_hnr) > 0 else 0,
                    'max_hnr': float(np.max(valid_hnr)) if len(valid_hnr) > 0 else 0,
                    'mean_pitch': float(np.mean(valid_pitch)) if len(valid_pitch) > 0 else 0
                })
            except:
                features.update({
                    'mean_hnr': 0,
                    'min_hnr': 0,
                    'max_hnr': 0,
                    'mean_pitch': 0
                })

        features.update(extract_spectral_features(segment))
        features.update(extract_formants_trajectory(segment))
        features.update(extract_temporal_dynamics(segment))
        
        return features
    except Exception as e:
        print(f"Error extracting features: {e}")
        return None

def main():
    all_features = []
    
    for speaker_dir in os.listdir(WAV_DIR):
        speaker_path = os.path.join(WAV_DIR, speaker_dir)
        if not os.path.isdir(speaker_path):
            continue
            
        print(f"\nProcessing speaker: {speaker_dir}")
        
        for filename in os.listdir(speaker_path):
            if filename.endswith('.TextGrid'):
                base_name = filename[:-9]
                textgrid_path = os.path.join(speaker_path, filename)
                wav_path = os.path.join(speaker_path, base_name + '.wav')
                
                try:
                    sound = parselmouth.Sound(wav_path)
                    tg = TextGrid()
                    tg.read(textgrid_path)
                    
                    for tier_idx, tier_type in [(1, 'fricative'), (2, 'approximant')]:
                        for interval in tg[tier_idx]:
                            if interval.mark:
                                print(f"\nProcessing interval: {interval.mark}")
                                metadata = parse_label(interval.mark)
                                if metadata:
                                    features = extract_features(sound, interval)
                                    if features:
                                        features.update(metadata)
                                        features.update({
                                            'speaker': speaker_dir,
                                            'file_name': base_name,
                                            'type': tier_type
                                        })
                                        
                                        intensity_tier = tg[5]
                                        p1, v, p2 = get_intensity_points(sound, intensity_tier,
                                                                        interval.minTime,
                                                                        interval.maxTime)
                                        
                                        if all(x is not None for x in [p1, v, p2]):
                                            mean_intensity_ratio = float(v) / ((float(p1) + float(p2)) / 2)
                                        else:
                                            mean_intensity_ratio = 0
                                            
                                        features.update({
                                            'p1_intensity': p1 if p1 is not None else 0,
                                            'v_intensity': v if v is not None else 0,
                                            'p2_intensity': p2 if p2 is not None else 0,
                                            'mean_intensity_ratio': mean_intensity_ratio
                                        })
                                                    
                                        features.update(calculate_intensity_ratios(p1, v, p2))
                                        all_features.append(features)
                                        print(f"Added features for {interval.mark}")
                                        
                except Exception as e:
                    print(f"Error processing {base_name}: {e}")
                    continue
    if all_features:
        try:
            results_df = pd.DataFrame(all_features)
            results_df['token_id'] = results_df['speaker'] + "-" + results_df['word']
            
            word_context = ['word', 'previous', 'target', 'following']
            phonetic_info = ['phoneme', 'tonicity', 'position']
            speaker_info = ['speaker', 'sex', 'age', 'file_name', 'type']
            acoustic_measures = [
                'duration',
                'spectral_centroid', 
                'spectral_spread',
                'spectral_kurtosis',
                'spectral_skewness',
                'spectral_tilt',
                'zero_crossing_rate',
                'z_crossings', 'z_crossings_ratio',
                'F1_start', 'F1_mid', 'F1_end',
                'F2_start', 'F2_mid', 'F2_end',
                'F3_start', 'F3_mid', 'F3_end',
                'mean_hnr', 
                'min_hnr', 
                'max_hnr',
                'mean_pitch'
            ]
            intensity_measures = [
                'p1_intensity', 'v_intensity', 'p2_intensity',
                'mean_intensity_ratio', 'p1_valley_ratio', 'p2_valley_ratio',
                'mean_log_ratio', 'rms_ratio', 'max_contrast'
            ]
            
            numeric_cols = acoustic_measures + intensity_measures
            cols_to_keep = [col for col in numeric_cols if not results_df[col].astype(float).eq(0).all()]
            ordered_cols = (['token_id'] + word_context + phonetic_info + speaker_info + cols_to_keep)
            
            results_df = results_df[ordered_cols]
            output_path = os.path.join(os.path.dirname(WAV_DIR), "abd_production_acoustic_features.csv")
            results_df.to_csv(output_path, index=False)
            
            print(f"\nProcessed {len(results_df)} tokens")
            print(f"Results saved to: {output_path}")
            
        except Exception as e:
            print(f"Error saving results: {e}")

if __name__ == "__main__":
    main()