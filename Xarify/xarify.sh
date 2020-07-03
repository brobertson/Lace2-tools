#!/bin/bash
#SBATCH --ntasks=10
#SBATCH --job-name=xarify
#SBATCH --mem=4G
#SBATCH --time=5-0:0
#SBATCH --output=/tmp/xarify.slurm.log

##### Helper functions ######

# This code integrates with the 'log' function above
# to ensure that only when verbose mode is on does
# the 'echo' and other stdout get output.
# This is useful to stop the various commandline commands
# below from spamming the output
exec 3>&1
exec 4>&2

# Usage notice and quit ####
function help() {
	log "Usage: xarify.sh [-f(orce)] [-i(mages excluded)] [-x(clude the texts)] [-o(ptimize images)] [-v(erbose)]"
   log -e "\t[-t binarization_level (default: 0.5)] [-s(erver url)] [-u(sername) ] [-p(assword)]"
   log -e "\t[-d accuracy threshold (default: 50)] [-g image.xar]"
   exit 1
}

# A replacement for 'echo': in this script, 'log'
# always prints, but 'echo' only prints when
# the -v[erbose] switch is on
function log() {
   #this is always seen
   echo "$@" 1>&3 2>&4
}

#### Functions End ####

# Set initial state of variables
server_url=False
username=admin
password=""
images_included=True
texts_included=True
verbose=False
force=False
optimize=False
binarization_level=0.5
accuracy_threshold=50
images_xar_file=""
needs_publishing=False
# Run getopts to gather the commandline options
while getopts ":fvhixot:s:p:d:u:g:" opt; do
   case ${opt} in
   f) # process option f
      force=True
      ;;
   v) # process option v
      verbose=True
      ;;
   d)
      accuracy_threshold=$OPTARG
      ;;
   s)
      server_url=$OPTARG
      ;;
   u)
      username=$OPTARG
      ;;
   p)
      password=$OPTARG
      ;;
   i)
      images_included=False
      ;;
   o)
      optimize=True
      ;;
   t)
      binarization_level=$OPTARG
      ;;
   x)
      texts_included=False
      ;;
   g)
      images_xar_file=$OPTARG
      ;;
   h) 
	help
	;;
   :)
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      help
      ;;

   \?)
      help
      ;;
   esac
done

# This code integrates with the 'log' function above
# to ensure that only when verbose mode is on does
# the 'echo' and other stdout get output.
# This is useful to stop the various commandline commands
# below from spamming the output
if [[ $verbose == "True" ]]; then
   echo "Verbose mode on."
else
   exec 1>/dev/null
   exec 2>/dev/null
fi

# get rid of the just-finished flag arguments
shift $((OPTIND - 1))

# TODO: put a loop here so that multiple directories
# can be added
for path in $@; do
   # Check that the path is, in fact, a directory
   if [ ! -d "${path}" ]; then
      log "\"$path\" is not a directory. Skipping ..."
      continue 
   fi
   if [ $1 = '.' ]; then
      path=$(pwd)
   fi
   log "Processing directory \"${path}\""
   cd $path >/dev/null
   fullpath=$(pwd)
   cd - >/dev/null
   dirname=$(basename $fullpath)
   innerPath=$fullpath/${dirname}-PNG-500
   smallImagePath=$innerPath/${dirname}_color

   if [ ! -d "${innerPath}" ]; then
      log "$path has no inner directory ${innerPath}. So I'm treating this directory as the one containing data."
      innerPath=$fullpath

   fi
   if [ -f "${innerPath}/${dirname}_meta.xml" ]; then
	   cp "${innerPath}/${dirname}_meta.xml" .
   fi
   metadatafile=$(pwd)/${dirname}_meta.xml
   if [ ! -f $metadatafile ]; then 
   #check if laceTexts.xml is a metadata file that has what we want. If it doesn't try to download
   #the archive.org metadata file. TODO: add hathitrust, etc.
   log "the metadata file is not at $metadatafile"
   metadatacatalog=$XARIFY_HOME/laceTexts.xml
   if [ -z "$(xsltproc --stringparam identifier $dirname $XARIFY_HOME/make_meta_images.xsl $metadatacatalog > $metadatafile)" ]; then
      echo "identifier $dirname is not in $metadatafile . Trying to download a metadata file from archive.org"
      wget -nv --no-check-certificate "http://www.archive.org/download/$dirname/${dirname}_meta.xml"
      if [ ! -f $metadatafile ]; then
         #ok, we've run out of ideas
         log "Failed to find ${dirname}_meta.xml at $metadatafile. Skipping ${dirname}."
         continue
      fi
   fi
   fi

   #### Images ###########
   if [[ $images_included == "True" ]]; then
      log "$path: processing images."
      #we now have the name for the file
      #let's build a temp file with links to the necessary
      #image file, and then zip from that and delete it

      if [[ ! -f $fullpath/$dirname-images.xar || $force == "True" ]]; then
         OUT=$(mktemp -d /tmp/$dirname.XXXXXXXXXX) || {
            echo "Failed to create temp file"
            exit 1
         }
      log "using temp dir: $OUT"
      cd $OUT >/dev/null
	          xsltproc  -v --stringparam identifier ${dirname} --stringparam scale 1.0 --output ./meta.xml $XARIFY_HOME/make_meta_images.xsl $metadatafile || {
            echo "Failed to generate meta.xml file. exiting ..."
            cd -
            rm -rf $OUT
            exit 1
         }
         xsltproc -v --stringparam identifier ${dirname} --output ./expath-pkg.xml $XARIFY_HOME/make_expath_images.xsl $metadatafile || {
            echo "Failed to generate expath file. exiting ..."
            cd -
            rm -rf $OUT
            exit 1
         }
         xsltproc -v --stringparam identifier ${dirname} --output ./repo.xml $XARIFY_HOME/make_repo_images.xsl $metadatafile || {
            echo "Failed to generate repo.xml file. exiting ..."
            cd -
            rm -rf $OUT
            exit 1
         }
         #check if there are xml files
         if [[ ! $? -eq 0 ]]; then
            log "no xml files were made. Exiting ..."
            log "the base file was $OUT"
            rm -rf $OUT
            continue
    	fi
         #find the original fullsized images
         #are they in this directory?
         ls $innerPath/*png >/dev/null
         if [[ ! $? -eq 0 ]]; then #we failed to find pngs here, so lets' go look for them
            if [ -z "$CIACONNA_TARS_DIR" ]; then
               log 'please set the env. variable $CIACONNA_TARS_DIR. Exiting ...'
               exit 1
            fi
            if [[ ! -f $CIACONNA_TARS_DIR/$dirname.tar.gz ]]; then
               log "there's no tar.gz on the local file system. Trying to download ..."
               #there isn't a tar file for them, so let's try to ssh it
               scp broberts@dtn.sharcnet.ca:/archive/broberts/Ciaconna_Results/Output_Tars/$dirname* $CIACONNA_TARS_DIR/
               if [[ ! $? -eq 0 ]]; then
                  log "failed to scp a pertinent file. Skipping ${dirname} ..."
                  continue
               fi
         fi
            #one way or another we have a file in the tar directory, let's uncompress it
            tar -C /tmp -xzf $CIACONNA_TARS_DIR/$dirname.tar.gz --wildcards --no-anchored '*png'
            #and move the image files
            cp /tmp/$dirname/*/*png ./
            rm -rf /tmp/$dirname
         else
            #the png files *are* here, so we'll just copy them
            cp $innerPath/*png ./
         fi
         log "$path: binarizing images at level $binarization_level"
         parallel -P 10 kraken -i {} {.}.bin.png binarize --threshold $binarization_level ::: *.png #parallel -P 10 ocropus-nlbin -t $binarization_level {} ::: *png
         rename -f 's/.bin.png/.png/' *png
         #rm *nrm.png
         if [[ $optimize == "True" ]]; then
            log "$path: Optimizing images ..."
            parallel -P 10 optipng {} ::: *png
         fi

         ln -s $XARIFY_HOME/StaticFilesForImageXar/* ./
         rm -f $fullpath/$dirname-images.xar
         zip -q -r $fullpath/$dirname-images.xar *
         size=$(ls -l $fullpath/$dirname-images.xar | cut -d " " -f5)
         echo "$dirname-imagesxar is $size bytes"
         unzip -l $fullpath/$dirname-images.xar
         if [ $size -gt 2147483647 ]; then
            log "xar is too large to upload into exist. Exiting."
            rm $fullpath/$dirname-images.xar
            rm -rf $OUT
         fi
         cd - >/dev/null

         log "$fullpath/$dirname-images.xar"
         if [[ $server_url != "False" ]]; then
            log "transfering file to $server_url"
	    #TODO test for failure. This isn't easy. The server will reply and give an exit of 0 even if we mess up.
            curl -F files[]=@$fullpath/$dirname-images.xar -u $username:$password http://${server_url}/exist/apps/public-repo/modules/upload.xql 
            #log "updating repo on $server_url"
            #curl -u admin: http://${server_url}/exist/apps/public-repo/index.html?publish=true
	    needs_publishing=True 
         fi
      else
         #the image.xar file already exists
         log "not making $fullpath/$dirname-images.xar because it already exists and you did not set the -f(orce) flag."
      fi
   fi #images included?

   ##Put text stuff here.
   #### Texts ####
   log "$path: Processing texts."
   if [[ $texts_included == "True" ]]; then
      for dir in $(ls $innerPath); do
         if [[ $dir =~ "selected_hocr" ]]; then
            log $dir
            shortend_dir_name="${dir::-21}"
            echo $shortend_dir_name
            sep="_"
            accuracy=$(python2 $CIACONNA_HOME/bin/Python/assess_hocr_dir.py $innerPath/$dir)
            log "acc. report: $accuracy"
            greek_accuracy=$(echo $accuracy | cut -c25-27)
            log "greek accuracy is $greek_accuracy; accuracy threshold is $accuracy_threshold"
            if [ $greek_accuracy -lt $accuracy_threshold ]; then
               log "the files in $innerPath/$dir have a Greek accuracy of $greek_accuracy, which is less than your threshold, $accuracy_threshold"
               log "therefore, we're skipping it."
               continue
            fi
	    if [ $greek_accuracy == "" ]; then
               log "\$greek_accuracy is null, which is fishy"
               log "therefore, we're skipping this file."
               continue
            fi
            rundate=${shortend_dir_name%%"$sep"*}
            if [ $(echo $rundate | wc -c) -eq 17 ]; then
               #add seconds as a new standard if this dir only uses minutes
               rundate=$rundate-00
            fi
            classifier=${shortend_dir_name#*"$sep"}
            echo "rundate: $rundate"
            echo "classifier: $classifier"
            if [[ $force != "True" ]] && [[ -f "$fullpath/$dirname-$rundate-$classifier-texts.xar" ]]; then
               log "$fullpath/$dirname-$rundate-$classifier-texts.xar exists already, and you did not set the -f button to force its re-generation. Skipping ..."
            else
               TEXTOUT=$(mktemp -d /tmp/$dirname.XXXXXXXXXX) || {
                  echo "Failed to create temp file"
                  exit 1
               }
               cd $TEXTOUT >/dev/null
               #build zippable directory in $TEXTOUT
               xsltproc --stringparam identifier ${dirname} --stringparam rundate ${rundate} --stringparam classifier ${classifier} --output $TEXTOUT/meta.xml $XARIFY_HOME/make_meta_texts.xsl $metadatafile || {
                  echo "Failed to generate meta.xml file. exiting ..."
                  cd -
                  rm -rf $OUT
                  exit 1
               }
               xsltproc --stringparam identifier ${dirname} --stringparam accuracy "[${accuracy}]" --stringparam rundate ${rundate} --output $TEXTOUT/repo.xml $XARIFY_HOME/make_repo_texts.xsl $metadatafile || {
                  echo "Failed to generate repo.xml file. exiting ..."
                  cd -
                  rm -rf $OUT
                  exit 1
               }
               xsltproc --stringparam identifier ${dirname} --stringparam rundate ${rundate} --output $TEXTOUT/expath-pkg.xml $XARIFY_HOME/make_expath_texts.xsl $metadatafile || {
                  echo "Failed to generate expath-pkg.xml file. exiting ..."
                  cd -
                  rm -rf $OUT
                  exit 1
               }
               cat $TEXTOUT/expath-pkg.xml
               ln -s $innerPath/$dir/*html ./
	       #TODO: check for the existence of the images.xar file! 'continue' if it doesn't exist
	       if [[ ! -f ${images_xar_file} ]]; then
		       images_xar_file=$fullpath/$dirname-images.xar
		fi
               python3 $CIACONNA_HOME/bin/Python/accuracySvgAndTotals.py ./ ${images_xar_file}
               ln -s $XARIFY_HOME/StaticFilesForTextXar/* ./
               rm -f $fullpath/$dirname-$rundate-$classifier-texts.xar
               zip -q -r $fullpath/$dirname-$rundate-$classifier-texts.xar *
               echo "Made text archive $fullpath/$dirname-$rundate-$classifier-texts.xar"
               cd - >/dev/null
               rm -rf $TEXTOUT
               if [[ $server_url != "False" ]]; then
                  log "transferring files to $server_url"
                  curl -F files[]=@$fullpath/$dirname-$rundate-$classifier-texts.xar -u $username:$password "http://${server_url}/exist/apps/public-repo/modules/upload.xql" 
                  #curl -u $username:$password "http://${server_url}/exist/apps/public-repo/index.html?publish=true"
		  needs_publishing=True 
               fi #done checking if we want to upload
            fi #done checking for clobbering
         fi #done checking that this directory is 'selected'
      done
   else
      log "$path: excluding text processing because -x flag was set."
   fi #done checking for include_texts
done # done looping through directory name arguments
if [[ $needs_publishing == "True" ]]; then
	log "updating repo at $server_url"
	curl -u $username:$password "http://${server_url}/exist/apps/public-repo/index.html?publish=true"
fi
