#!/bin/sh

#  Test.sh
#  
#
#  Created by edwin ripaud on 17/03/2022.
#  

FNCDIR="/Volumes/Edwin SSD 1/5 - Astrophoto/AstroImageClissifier/"
FNCNAME=(Param_func.sh)
if [ -d $FNDIR ]
then
    for h in ${FNCNAME[@]}
    do
        f="$FNCDIR$h"
        test -x "$f" && source "$f"
    done
fi

#source "/Volumes/Edwin SSD 1/5 - Astrophoto/AstroImageClissifier/Param_func.sh"

read_param
