# This script takes a folder of sound files and for each sound file,
# it calculates the duration and intensity of those intervals in the selected tier.
# You can also give the name of a criterion tier and a criterion label:
# only those segments will be counted that are part of an interval in the
# criterion tier that has the criterion label. 
# A TextGrid object has to be selected before running this script in the Object Window.
#
# This script is distributed under the GNU General Public Licence.
# Copyright 09.22.2023 Santiago Arroniz


# Setting User Input Form

form Calculate the total duration of intervals
	comment Calculate the duration of intervals in tier:
	integer Duration_tier 1
	comment Calculate the intensity at all points in tier:
	integer Intensity_tier 3
	comment Empty intervals will not be measured.
	word Sound_file_extension .TextGrid
	comment Additional criterion for included intervals: They must be part of intervals in tier number
	integer Criterion_tier 0
	comment that are labeled as:
	sentence Label 
endform



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




# Looping over the files
 
directory$ = chooseDirectory$: "Choose a directory with 'sound_file_extension$'
... files to analize."
@getFiles: directory$, sound_file_extension$

total_duration = 0
count = 0

	
# Loop through all intervals in the selected tier:

for i to getFiles.length
    soundfile = Read from file: getFiles.files$ [i]
	numberOfIntervals = Get number of intervals... duration_tier
	for i from 1 to numberOfIntervals
	
		label1$ = Get label of interval... duration_tier i

		# The next line will make sure that intervals with empty labels are not included:
		if label1$ <> ""

			start1 = Get starting point... duration_tier i	
			end1 = Get end point... duration_tier i
			duration = end1 - start1
			middle1 = (start1 + end1) / 2
			printline 'label1$' duration is: 'duration'

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
		endif
	endfor

	numberOfPoints = Get number of points... intensity_tier
	for i from 1 to numberOfPoints

		label3$ = Get label of point... intensity_tier i

		# The next line will make sure that intervals with empty labels are not included:
		if label3$ <> ""
			intensity = Select Intensity... intensity_tier i	
			printline 'label3$' intensity is: 'intensity'
		endif
	endfor		

    removeObject: soundfile

endfor



