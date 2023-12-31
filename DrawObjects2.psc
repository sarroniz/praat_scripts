## DRAW OBJECTS
## July 28, 2005
## Francisco Torreira
## ftorrei22uiuc.edu

# Only a Sound and optionally a TextGrid with the same name are needed in 
# the Object Window.
# Spectrogram and Pitch objects will be created by the script.
# Don't deselect the picture before saving it, since it cannot
# be selected manually at the proper margins. If this happens,
# just run the script one more time and save the picture before
# clicking on the Praat picture window.


form DRAW OBJECTS
comment Draw:
	boolean Waveform 1
	boolean Spectrogram 0
	boolean F0 0
	boolean TextGrid 0
real Spectrogram_frequency_range 5000
real left_F0_range 75
real right_F0_range 200
real Picture_width 6
boolean Draw_boundaries 0
endform

# Font size
10
#

Line width... 1


name$ = selected$ ("Sound")

if draw_boundaries = 1 and textGrid = 0
	exit In order to draw boundaries, Draw TextGrid must be selected.
endif

if textGrid = 1
	call examine_tiers
endif	

Erase all

if waveform = 1 and spectrogram = 0 and f0 = 0
	select Sound 'name$'
	Select inner viewport... 0.5 picture_width 0.5 2.5
	Plain line
	Draw... 0 0 0 0 no curve
	Draw inner box
	
	if draw_boundaries = 1
		min = Get minimum... 0 0 Sinc70
		max = Get maximum... 0 0 Sinc70
		call boundaries
	endif

	if textGrid = 1
		select TextGrid 'name$'
		nt = Get number of tiers
		x = 2.65 + (nt * 0.50) + (nt * 0.045)
		Select inner viewport... 0.5 picture_width 0.5 x
		Plain line
		Draw... 0 0 no yes no
	endif

	if waveform = 1 and textGrid = 1
		Select inner viewport... 0.5 picture_width 0.5 x
	elsif waveform = 1 and textGrid = 0
		Select inner viewport... 0.5 picture_width 0.5 2.50	
	endif

	Text bottom... yes Time (s)
	select Sound 'name$'
	ft = Get finishing time
	One mark bottom... 'ft:3' yes no no
	One mark bottom... 0 yes no no


endif


if (spectrogram = 1 and f0 = 0) or (spectrogram = 0 and f0 = 1)

	if waveform = 1
		select Sound 'name$'
		Select inner viewport... 0.5 picture_width 0.5 1.5
		Plain line
		Draw... 0 0 0 0 no curve
		Draw inner box
		
		if draw_boundaries = 1
			min = Get minimum... 0 0 Sinc70
			max = Get maximum... 0 0 Sinc70
			call boundaries
		endif
	endif
	

	if spectrogram = 1
		select Sound 'name$'
		To Spectrogram... 0.005 spectrogram_frequency_range 0.002 20 Gaussian
		select Spectrogram 'name$'
		Select inner viewport... 0.5 picture_width 1.65 3.65
		Paint... 0 0 0 0 100 yes 50 6 0 no
		Draw inner box
		Text left... no Frequency (Hz)
		Font size... 9
		One mark left... 0 yes no no
		One mark left... spectrogram_frequency_range yes no no
		Font size... 10
		Remove

		if draw_boundaries = 1
			min = 0
			max = spectrogram_frequency_range
			call boundaries
		endif
	
	elsif f0 = 1
		select Sound 'name$'
		To Pitch... 0 75 600
		Select inner viewport... 0.5 picture_width 1.65 3.65
		Speckle... 0 0 left_F0_range right_F0_range no
		Draw inner box
		Text left... no F0 (Hz)
		Font size... 9
		One mark left... right_F0_range yes no no
		One mark left... left_F0_range yes no no
		Font size... 10
		Remove
	
		if draw_boundaries = 1
			min = left_F0_range
			max = right_F0_range
			call boundaries
 		endif

	endif

	if textGrid = 1
			select TextGrid 'name$'
			nt = Get number of tiers
			x = 3.80 + (nt * 0.50) + (nt * 0.045)
			Select inner viewport... 0.5 picture_width 1.65 x
			Plain line
			Draw... 0 0 no yes no
	endif

	if waveform = 1 and textGrid = 1
		Select inner viewport... 0.5 picture_width 0.5 x
	elsif waveform = 1 and textGrid = 0
		Select inner viewport... 0.5 picture_width 0.5 3.65	
	elsif waveform = 0 and textGrid = 0
		Select inner viewport... 0.5 picture_width 1.65 3.65
	elsif waveform = 0 and textGrid = 1
		Select inner viewport... 0.5 picture_width 1.65 x
	endif

	Text bottom... yes Time (s)
	select Sound 'name$'
	ft = Get finishing time
	Font size... 9
	One mark bottom... 'ft:3' yes no no
	One mark bottom... 0 yes no no
	Font size... 10
endif



if spectrogram = 1 and f0 = 1
	
	if waveform = 1
		select Sound 'name$'
		Select inner viewport... 0.5 picture_width 0.5 1.5
		Plain line
		Draw... 0 0 0 0 no curve
		Draw inner box
	
		if draw_boundaries = 1
			min = Get minimum... 0 0 Sinc70
			max = Get maximum... 0 0 Sinc70
			call boundaries
		endif

	endif

	select Sound 'name$'
	To Spectrogram... 0.005 spectrogram_frequency_range 0.002 20 Gaussian
	select Spectrogram 'name$'
	Select inner viewport... 0.5 picture_width 1.65 2.65
	Paint... 0 0 0 0 100 yes 50 picture_width 0 no
	Draw inner box
	Text right... no Freq (Hz)
	Font size... 9
	One mark right... 0 yes no no
	One mark right... spectrogram_frequency_range yes no no
	Font size... 10
	Remove
	
	if draw_boundaries = 1
		min = 0
		max = spectrogram_frequency_range
		call boundaries
	endif
	
	select Sound 'name$'
	To Pitch... 0 75 600
	Select inner viewport... 0.5 picture_width 2.80 4.80
	Speckle... 0 0 left_F0_range right_F0_range no
	Draw inner box
	Text left... no F0 (Hz)
	Font size... 9
	One mark left... right_F0_range yes no no
	One mark left... left_F0_range yes no no
	Font size... 10
	Remove

	if draw_boundaries = 1
		min = left_F0_range
		max = right_F0_range
		call boundaries
	endif

	if textGrid = 1
		select TextGrid 'name$'
		nt = Get number of tiers
		x = 4.95 + (nt * 0.50) + (nt * 0.045)
		Select inner viewport... 0.5 picture_width 2.80 x
		Plain line
		Draw... 0 0 no yes no
	endif

	if waveform = 1 and textGrid = 1
		Select inner viewport... 0.5 picture_width 0.5 x
	elsif waveform = 1 and textGrid = 0
		Select inner viewport... 0.5 picture_width 0.5 4.80	
	elsif waveform = 0 and textGrid = 0
		Select inner viewport... 0.5 picture_width 1.65 4.80 	
	elsif waveform = 0 and textGrid = 1
		Select inner viewport... 0.5 picture_width 1.65 x
	endif

	Text bottom... yes Time (s)
	select Sound 'name$'
	ft = Get finishing time
	Font size... 9
	One mark bottom... 'ft:3' yes no no
	One mark bottom... 0 yes no no
	Font size... 10
endif

## Procedures

procedure boundaries
	select TextGrid 'name$'
	Dotted line
	Line width... 1
			for n to np1
				if isint1 = 0
					t = Get time of point... 1 n
				elsif isint1 = 1
					t = Get end point... 1 n
				endif
				Draw line... t min t max
			endfor
		
			if nt = 2
				for n to np2	
					if isint2 = 0
						t = Get time of point... 2 n
					elsif isint2 = 1
						t = Get end point... 2 n
					endif
				Draw line... t min t max
				endfor
			
			elsif nt = 3
				for n to np2	
					if isint2 = 0
						t = Get time of point... 2 n
					elsif isint2 = 1
						t = Get end point... 2 n
					endif
				Draw line... t min t max
				endfor

				for n to np3
					if isint3 = 0
						t = Get time of point... 3 n
					elsif isint3 = 1
						t = Get end point... 3 n
					endif
				Draw line... t min t max
		    		endfor
			endif
	Plain line
	Line width... 1
endproc


procedure examine_tiers
	select TextGrid 'name$'
	nt = Get number of tiers
	if nt = 1
		isint1 = Is interval tier... 1
			if isint1 = 0
				np1 = Get number of points... 1
			elsif isint1 = 1
				ni1 = Get number of intervals... 1
				np1 = ni1 - 1
			endif
	elsif nt = 2
		isint1 = Is interval tier... 1
			if isint1 = 0
				np1 = Get number of points... 1
			elsif isint1 = 1
				ni1 = Get number of intervals... 1
				np1 = ni1 - 1
			endif
		isint2 = Is interval tier... 2
			if isint2 = 0
				np2 = Get number of points... 2
			elsif isint2 = 1
				ni2 = Get number of intervals... 2
				np2 = ni2 - 1
			endif
	elsif nt = 3
		isint1 = Is interval tier... 1
			if isint1 = 0
				np1 = Get number of points... 1
			elsif isint1 = 1
				ni1 = Get number of intervals... 1
				np1 = ni1 - 1
			endif
		isint2 = Is interval tier... 2
			if isint2 = 0
				np2 = Get number of points... 2
			elsif isint2 = 1
				ni2 = Get number of intervals... 2
				np2 = ni2 - 1
			endif
		isint3 = Is interval tier... 3
			if isint3 = 0
				np3 = Get number of points... 3
			elsif isint3 = 1
				ni3 = Get number of intervals... 3
				np3 = ni3 - 1
			endif
	endif	
endproc