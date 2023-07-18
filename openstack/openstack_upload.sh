#!/bin/bash -l

. Ivan_testing-openrc.sh
source openstack/bin/activate

download_path="../downloads/"

final_name="Flight Solo ${version}-${rc}-${release_date}"

final_name="test-o-image1"

filename="Flight_Solo_2023-4_generic-cloudinit.raw"

# check if the image already exists


openstack image list -f value | grep "$final_name"; result=$?

if [[ $result != 1 ]]; then
  echo "image already exists/ duplicate checking failed"
  exit 1
fi

# now upload it

create_out=$(openstack image create --disk-format raw  --shared --file "${download_path}${filename}" --min-disk 10 --min-ram 2048 "$final_name" --format yaml)

echo "$create_out"

echo "$create_out" | grep "id:"

id_line=$(echo "$create_out" | grep "id:")

id=$(echo "${id_line#*:}"| xargs)

echo "id: $id" 


openstack image show "$id" -f yaml | grep "status" | grep "active"; result=$?
counter=60
while [[ $result != 0 ]]; do
  count=$((counter-=1))
  sleep 1
  openstack image show "$id" -f yaml | grep "status" | grep "active"; result=$?
done

if [[ $counter -le 0 ]]; then
  echo "upload check timed out"
  exit 1
fi

echo "image uploaded and activated"

