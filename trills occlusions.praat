#
# occlusions.praat
#
# Maxim Aleksa
# maximal@umich.edu
#
# Calculates the duration of the occlusions in ms in all .wav sound file
# in a directory from TextGrid objects of the same name.
# Each labeled interal in the TextGrid must contain the number of occlusions
# followed by the word (e.g. 2rana).
# It is assumed that the number of occlusions is always between 0 and 9.
#

# Ask user for paths to files
form Calculate duration of occlusions
	comment Enter the complete path to the directory with sound files and TextGrids:
	text directory 
	comment Enter the complete path to the resulting file:
	text result 
endform

# Write header row
appendFileLine: "'result$'", "File name'tab$'Word'tab$'Number of occlusions'tab$'Duration (ms)"

# Read all files in the folder
Create Strings as file list... wavlist 'directory$'/*.wav
Create Strings as file list... gridlist 'directory$'/*.TextGrid
n = Get number of strings

# Interate over sound files
for i to n
	# Open sound file
	select Strings wavlist
	filename$ = Get string... i
	Read from file... 'directory$'/'filename$'

	# Open text grid
	select Strings gridlist
	gridname$ = Get string... i
	Read from file... 'directory$'/'gridname$'

	# Iterate over intervals
	numberOfIntervals = Get number of intervals... 1
	for j from 1 to numberOfIntervals
		label$ = Get label of interval... 1 j

		# If the interval is labelled...
		if label$ <> ""
			# Get duration
			startTime = Get starting point... 1 j
			endTime = Get end point... 1 j
			duration = (endTime - startTime) * 1000

			# Get word
			numberOfOcclusions$ = left$ (label$, 1)
			wordLength = length (label$)
			word$ = right$ (label$, wordLength - 1)

			# Write row to file
			appendFileLine: "'result$'", "'filename$''tab$''word$''tab$''numberOfOcclusions$''tab$''duration'"
		endif
	endfor
endfor

# Clean up
select all
Remove