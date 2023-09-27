import pickle
import numpy as np
import os
import re
import sys
import argparse 

## Defining argument parsing
def argument_parse(argv):
    parser=argparse.ArgumentParser(description='Unpickle chacovol and chacoconn files from the NeMo tool')
    
    parser.add_argument('pikelfiles',nargs='*',action='store',help='pkl files from the nemo-output (eg. .pkl files with chacovol or chcacoconn)')

    args=parser.parse_args(argv)
    
    return args

## Defining very short function for reading, treating and outputting for each
## provided file to the script. Based on the NeMo tool naming 
## Wish list
## - would be better to base if statements on data format, not file naming
def write_output(inputfile):
  
    for i in inputfile:
          path=i
          data = pickle.load(open(path,"rb"))
          if bool(re.search('chacoconn', path)):
              np.savetxt(os.path.splitext(path)[0]+'.tsv',data.toarray(),delimiter="\t")
          elif bool(re.search('chacovol', path)):
              np.savetxt(os.path.splitext(path)[0]+'.tsv',data,delimiter="\t")
  
    return path 

## Run the functions based on provided inputfiles
if __name__ == "__main__":
    args=argument_parse(sys.argv[1:])
    write_output(args.pikelfiles)
  
