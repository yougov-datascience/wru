from pdb import set_trace as t
import csv
import sys

# hard code the file paths
paths = ['2020october05/VM2--SC--2020-10-01-DEMOGRAPHIC.tab',
			'2021january26/VM2--LA--2021-01-22-DEMOGRAPHIC.tab',
			'2021february07/VM2--NC--2021-01-28-DEMOGRAPHIC.tab',
			'2021february07/VM2--AL--2021-02-04-DEMOGRAPHIC.tab',
			'2021february07/VM2--FL--2021-02-04-DEMOGRAPHIC.tab',
			'2021february07/VM2--GA--2021-02-04-DEMOGRAPHIC.tab']
			
# get arguments from the command line
mode = sys.argv[1]
if mode == 'first':
	nameCol = 14
elif mode == 'middle':
	nameCol = 15
elif mode == 'last':
	nameCol = 16
else:
	print 'Mode must be first, middle, or last'
	t()

if sys.argv[2] == 'yes':
	genderSegregation = True
elif sys.argv[2] == 'no':
	genderSegregation = False
else:
	print "Yes or no to gender segregation?"
	t()
	
# set up the data dictionary
if genderSegregation:
	maleNames = dict()
	femaleNames = dict()
	unknownNames = dict()
else:
	names = dict()

# iterate through the file paths
for path in paths:
	fullPath = '/nfs/home/E/etr496/shared_space/ci3_l2_bigdata/CronJob/' + path
	
	print(path)
	
	# read in the csv file
	cntr = 0
	with open(fullPath) as infile:
		reader = csv.reader(infile, delimiter = '\t')
		next(infile)
	
		# read in the file line by line 
		for line in reader:
			
			cntr += 1
			if cntr % 500000 == 0:
				print(cntr)
				
			# case with gender segregation
			if genderSegregation:
				if line[65] == 'M':
					if line[nameCol] in maleNames:
						if line[74] in maleNames[line[nameCol]]:
							maleNames[line[nameCol]][line[74]] += 1
						else:
							maleNames[line[nameCol]][line[74]] = 1
					else:
						maleNames[line[nameCol]] = {}
						maleNames[line[nameCol]][line[74]] = 1
				elif line[65] == 'F':
					if line[nameCol] in femaleNames:
						if line[74] in femaleNames[line[nameCol]]:
							femaleNames[line[nameCol]][line[74]] += 1
						else:
							femaleNames[line[nameCol]][line[74]] = 1
					else:
						femaleNames[line[nameCol]] = {}
						femaleNames[line[nameCol]][line[74]] = 1
				else:
					if line[nameCol] in unknownNames:
						if line[74] in unknownNames[line[nameCol]]:
							unknownNames[line[nameCol]][line[74]] += 1
						else:
							unknownNames[line[nameCol]][line[74]] = 1
					else:
						unknownNames[line[nameCol]] = {}
						unknownNames[line[nameCol]][line[74]] = 1

			# case without gender segregation
			else:
				if line[nameCol] in names:
					if line[74] in names[line[nameCol]]:
						names[line[nameCol]][line[74]] += 1
					else:
						names[line[nameCol]][line[74]] = 1
				else:
					names[line[nameCol]] = {}
					names[line[nameCol]][line[74]] = 1
					

ethnicities = ['', 'Native American (self reported)', 'East Asian', 'African or Af-Am Self Reported', 'Hispanic', 'White Self Reported', 'Other Undefined Race']

# write the csv file(s)
if genderSegregation:
	print('Male names: ' + str(len(maleNames)) + ', female names: ' + str(len(femaleNames)) + ', unknown names: ' + str(len(unknownNames)))
	
	maleFile = 'nameRatios_full_male_' + mode + '.csv'
	with open(maleFile, 'w') as f:
		writer = csv.writer(f, delimiter = ',')	
		writer.writerow(['Name', 'No Race', 'Native American (self reported)', 'East Asian', 'African or Af-Am Self Reported', 'Hispanic', 'White Self Reported', 'Other Undefined Race'])	
		for key in maleNames.keys():
			writer.writerow([key] + [maleNames[key].get(v, 0) for v in ethnicities])

	femaleFile = 'nameRatios_full_female_' + mode + '.csv'
	with open(femaleFile, 'w') as f:
		writer = csv.writer(f, delimiter = ',')	
		writer.writerow(['Name', 'No Race', 'Native American (self reported)', 'East Asian', 'African or Af-Am Self Reported', 'Hispanic', 'White Self Reported', 'Other Undefined Race'])	
		for key in femaleNames.keys():
			writer.writerow([key] + [femaleNames[key].get(v, 0) for v in ethnicities])

	unknownFile = 'nameRatios_full_unknown_' + mode + '.csv'
	with open(unknownFile, 'w') as f:
		writer = csv.writer(f, delimiter = ',')	
		writer.writerow(['Name', 'No Race', 'Native American (self reported)', 'East Asian', 'African or Af-Am Self Reported', 'Hispanic', 'White Self Reported', 'Other Undefined Race'])	
		for key in unknownNames.keys():
			writer.writerow([key] + [unknownNames[key].get(v, 0) for v in ethnicities])
	
else:
	outfile = 'nameRatios_full_' + mode + '.csv'
	with open(outfile, 'w') as f:
		writer = csv.writer(f, delimiter = ',')	
		writer.writerow(['Name', 'No Race', 'Native American (self reported)', 'East Asian', 'African or Af-Am Self Reported', 'Hispanic', 'White Self Reported', 'Other Undefined Race'])	
	
		for key in names.keys():
			writer.writerow([key] + [names[key].get(v, 0) for v in ethnicities])
	
