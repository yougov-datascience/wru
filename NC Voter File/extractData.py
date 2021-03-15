from pdb import set_trace as t
import csv
import sys
import random

# hard code the file paths
inPath = 'ncvoter_Statewide.txt'
outPath = 'ncvoter_Statewide_sample.csv'

with open(inPath) as infile:
	with open(outPath, 'w') as outfile:

		reader = csv.reader(infile, delimiter = '\t')
		writer = csv.writer(outfile, delimiter = ',')

		headerLine = next(reader)
		header = [headerLine[i] for i in [0, 1, 9, 10, 11, 16, 25, 26, 27, 28, 29, 46, 47, 67]]
		writer.writerow(header)

		cntr = 0
		for line in reader:

			cntr += 1
			if cntr % 100000 == 0:
				print(cntr)

			if(random.uniform(1, 0) > 0.95):
				shortenedLine = [line[i] for i in [0, 1, 9, 10, 11, 16, 25, 26, 27, 28, 29, 46, 47, 67]]
				writer.writerow(shortenedLine)