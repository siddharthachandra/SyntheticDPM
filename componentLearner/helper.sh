#!/bin/bash
#$-cwd
class=$1
matlab -nosplash -nodisplay -r "genParts('${class}')"
