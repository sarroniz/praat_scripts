# This script takes a folder of sound files and for each sound file,
# it calculates the duration and intensity of those intervals in the selected tier.
# You can also give the name of a criterion tier and a criterion label:
# only those segments will be counted that are part of an interval in the
# criterion tier that has the criterion label. 
# Results will be saved in the same directory as the input source. 
#
# This script is distributed under the GNU General Public Licence.
# Copyright 09.22.2023 Santiago Arroniz


# Setting User Input Form

form Calculate the total duration of intervals and intensity of points
	comment Calculate the duration of intervals in tier:
	integer Duration_tier 1
	comment Calculate the intensity at all points in tier:
	integer Intensity_tier 3
	comment Empty intervals will not be measured.
	word Sound_file_extension .wav
	comment Additional criterion for included intervals: They must be part of intervals in tier number
	integer Criterion_tier 0
	comment that are labeled as:
	sentence Label
	comment Duration results CSV file name: 
	word Results_duration duration_results.csv
	comment Intensity results CSV file name: 
	word Results_intensity intensity_results.csv
endform



# Looping over the files
directory$ = chooseDirectory$: "Choose a directory with 'sound_file_extension$'
... files to analize."
@getFiles: directory$, sound_file_extension$

# Set counters for duration values
total_duration = 0
count = 0

# We print out the file names
pathDur$ = "'directory$'/'results_duration$'"
pathInt$ = "'directory$'/'results_intensity$'"
	
fileappend "'pathDur$'" File Name,Target,Word,Segment 1,Segment 2,Segment 3,Tonicity,Interval name,Duration
fileappend "'pathDur$'" 'newline$'

fileappend "'pathInt$'" File Name,Target,Word,Segment 1,Segment 2,Segment 3,Tonicity,Interval name,Intensity
fileappend "'pathInt$'" 'newline$'


# Loop through all intervals in the selected tier:
for j to getFiles.length
    	soundfile = Read from file: getFiles.files$ [j]
	soundname$ = selected$ ("Sound")
	To Intensity... 100 0

	@getTextGrid: getFiles.files$ [j]
	numberOfIntervals = Get number of intervals... duration_tier
	numberOfPoints = Get number of points... intensity_tier
	
	for i from 1 to numberOfIntervals
	
		label1$ = Get label of interval... duration_tier i
		@splitstring(soundname$, "-")
		target$ = splitstring.array$[1]
		word$ = splitstring.array$[2]
		segment1$ = splitstring.array$[3]
		segment2$ = splitstring.array$[4]
		segment3$ = splitstring.array$[5]
		tonicity$ = splitstring.array$[6]


		# The next line will make sure that intervals with empty labels are not included:
		if label1$ <> ""

			start1 = Get starting point... duration_tier i	
			end1 = Get end point... duration_tier i
			duration = end1 - start1
			middle1 = (start1 + end1) / 2
			

			if criterion_tier > 0
				criterion = Get interval at time... criterion_tier middle1
				start2 = Get starting point... criterion_tier criterion
				end2 = Get end point... criterion_tier criterion
		
				label2$ = Get label of interval... criterion_tier criterion
			
				if start2 <= start1 and end2 >= end1 and label2$ = label$
					total_duration = total_duration + duration
					count = count + 1
				endif
			else
				total_duration = total_duration + duration
				count = count + 1	
			endif
			fileappend "'pathDur$'" 'soundname$','target$','word$','segment1$','segment2$','segment3$','tonicity$','label1$','duration'
			fileappend "'pathDur$'" 'newline$'
		endif
	endfor

	for i from 1 to numberOfPoints
		select TextGrid 'soundname$'
		label3$ = Get label of point... intensity_tier i

		# The next line will make sure that intervals with empty labels are not included:
		if label3$ <> ""
			onset = Get starting point... 1 'i'
  			offset = Get end point... 1 'i'
			select Intensity 'soundname$'
			max_int = Get maximum... onset offset Parabolic
			fileappend "'pathInt$'" 'soundname$','target$','word$','segment1$','segment2$','segment3$','tonicity$','label3$','max_int'
			fileappend "'pathInt$'" 'newline$'
		endif
	endfor		

    removeObject: soundfile

endfor

# Show a message indicating the completion of the analysis
printline "Analysis completed. Results are saved in the specified CSV files."

##########################################################################

# Setting Procedures

procedure getFiles: .dir$, .ext$
    .obj = Create Strings as file list: "files", .dir$ + "/*" + .ext$
    .length = Get number of strings

    for .i to .length
        .fname$ = Get string: .i
        .files$ [.i] = .dir$ + "/" + .fname$

    endfor

    removeObject: .obj

endproc

procedure getTextGrid: .soundfile$
    .path$ = replace$: .soundfile$, sound_file_extension$, ".TextGrid", 0
    .textgrid = Read from file: .path$

    endif

endproc

procedure splitstring: .string$, .sep$
    .strLen = 0
    repeat
        .sepIndex = index (.string$, .sep$)
        if .sepIndex <> 0
            .value$ = left$ (.string$, .sepIndex - 1)
            .string$ = mid$ (.string$, .sepIndex + 1, 10000)
        else
            .value$ = .string$
        endif
        .strLen = .strLen + 1
        .array$[.strLen] = .value$
    until .sepIndex = 0
endproc
# End of the script