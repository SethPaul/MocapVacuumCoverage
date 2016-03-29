# MocapVacuumCoverage
Coverage and passes script for processing of motion capture data for a vacuum ergonomic comparison study

Script takes 3D coordinates of motion capture markers located on the ends of a vacuum wand, <br>


Frame Number|x1|y1|z1|x2|y2|z2
--|-|-|-|-|-|-
1	| 0.0099998333 |	0.9999500021 |	0.0149995 |		0.5099498354 |	0.8727689958 |	0.0149995
2	| 0.0199986667 |	0.9998000333 |	0.0149980001 |		0.5197987	| 0.8679191841	| 0.0149980001
3	| 0.0299955002 |	0.9995501687 |	0.0149955003 |		0.5295456689 |	0.863036661	|0.0149955003
4	| 0.0399893342 |	0.9992005331 |	0.0149920011 |		0.5391898673 |	0.8581249182 |	0.0149920011
5	| 0.0499791693 |	0.9987513013 |	0.0149875026 |		0.5487304706 |	0.8531874017 |	0.0149875026
... | ... | ... | ... | ... | ... | ...

and calculates the estimated floor coverage at each frame.

The final coverage and number of passes can be seen from the generated pngs.
###### Coverage over time
![coverage over time](/output/VacTwo_percentCovered.png)

###### Areas that were not covered during the trial shown in red.
![No passes](/output/VacTwo_noPasses.png)

###### Heat map of number of passes during the trial, increasing from 1 pass (dark blue) to 8 pasess (dark red).
![Number of passes](/output/VacTwo_passes.png)

###### An example video of the trial coverage can be downloaded at https://raw.githubusercontent.com/SethPaul/MocapVacuumCoverage/blob/master/output/vacTest_compressed.avi
