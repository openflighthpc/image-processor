#!/bin/bash -l

# download an image with an s3 link e.g. s3://flight-images/SOLO2-2023.4-2006231854_generic-cloudinit.raw

link="s3://flight-images/SOLO2-2023.4-2006231854_generic-cloudinit.raw"
input=true
platform="" # aws/openstack/azure
rc="rc-"
release_date=""
version=""
dl_filepath="downloads/"

while [[ $# -gt 0 ]]; do # while there are not 0 args
  case $1 in
    -l|--link)
      link="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--platform)
      platform="$2"
      shift # past argument
      shift # past value
      ;;
    -f|--filepath)
      dl_filepath="$2"
      shift # past argument
      shift # past value
      ;;
    -i|--no-input)
      input=false
      shift # past argument
      ;;
    -v|--var) # -v var_name=value
      in="$2"
      var=${in%=*}
      val=${in#*=}
      declare "${var}"="$val"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      echo "-l, --link LINK                  the s3 link to use"
      echo "-p, --platform PLATFORM          the platform this is for"
      echo "-f, --filepath FILEPATH          the filepath to download to"
      echo "-i, --no-input                   don't accept input interactively."
      echo '-v, --var "VARNAME=VAR"          pass a variable to the program'
      echo "--noinput                        program won't ask for input"
      exit 2
      shift # past argument
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

if [[ $input == true ]]; then
  echo "s3 link for image raw file?"
  read link
  echo "What platform is the image going to be on? (leave blank for smart analysis)"
  read platform
  echo "what is the version number (e.g. 2023.4)"
  read version
  echo "What release candidate is this?"
  read rc
  echo "What is the release date?"
  read release_date
fi


# actually download the image
aws s3 cp "$link" "$dl_filepath"
