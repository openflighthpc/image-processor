#!/bin/bash -l


storage_account_name="openflightimages"
container_name="images"
local_image_filepath="downloads/"
upload_resource_group="openflight-images"
build_number="rc"

# get data
while [[ $# -gt 0 ]]; do # while there are not 0 args
  case $1 in
    -p|--parameter) # -p var_name=value   '-p, --parameter "PARAMETERNAME=PARAMETER"   pass a parameter to the program'
      in="$2"
      var=${in%=*}
      val=${in#*=}
      declare "${var}"="$val"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo -e "${RED}Unknown option $1 ${NC}"
      echo "Try '--help' for more information."
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done



storage_blob_name=${local_image_filepath##*/}; storage_blob_name=${storage_blob_name%.*} ; echo "Storage blob name: $storage_blob_name"

version_number=${storage_blob_name#*-}; version_number=${version_number%-*} ; echo "version number: $version_number"
build_date=${storage_blob_name##*-}; build_date=${build_date%_*} ; echo "build date: $build_date"
image_name="Flight-Solo-$version_number-$build_number-$build_date" ; echo "image name: $image_name"
# https://wiki.bash-hackers.org/syntax/pe
# Flight-Solo-2023.1-rc5-03.02.2023

# upload a storage blob

az storage blob upload --account-name "$storage_account_name" --container-name $container_name --type page --file "$local_image_filepath" --name "$storage_blob_name.vhd"

echo "storage blob upload complete"
# create an image from the storage blob
echo "test 1:"
echo "https://""$storage_account_name"".blob.core.windows.net/""$container_name""/""$storage_blob_name"".vhd" # next time i run this want to see if i wrote this right

az image create --resource-group "$upload_resource_group" \
    --name "$image_name" \
    --os-type Linux \
    --hyper-v-generation V2 \
    --source "https://""$storage_account_name"".blob.core.windows.net/""$container_name""/""$storage_blob_name"".vhd"

echo "image create complete"
# create another image but in a different region

az image copy --source-resource-group "$upload_resource_group" --source-object-name "$image_name" --target-location "westeurope" --target-resource-group "$upload_resource_group" --cleanup

echo "image region change complete"

echo "image uploaded and copied to requested region"

