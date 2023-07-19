# image-processor
From s3 link to raw file to cloud platform image.



## Setup


### Installations:
```
sudo yum install -y git unzip python3-pip
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo yum install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo yum install -y azure-cli
```


### Setup aws

Download this zip file
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```
unzip it 
```
unzip awscliv2.zip
```
install the unzipped folder
```
sudo ./aws/install
```
Configure credentials by running this command, then following the instructions
```
aws configure
```

Configuration example that I do:
```
[user@machine ~]$ aws configure
AWS Access Key ID [None]: ***
AWS Secret Access Key [None]: ***
Default region name [None]: eu-west-2
Default output format [None]: 
```
*Note that \*\*\* is where you would put your access key and secret access key, don't actually put asterisks*
[Source](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)





### Setup azure

Required software was installed during the installation step, simply authenticate with:
```
az login
```

You will need a web browser (doesn't have to be on this machine), a microsoft account and azure credentials


### Get the git repo
Get the repo
```
git clone https://github.com/openflighthpc/image-processor.git
```

### Setup Openstack
```
cd image-processor/openstack/
```

#### create a directory with a python "virtual environment" called "openstack" 
```
python3 -m venv openstack 
```

#### activate the openstack virtual environment
```
source openstack/bin/activate
```

#### check no openstack packages
```
pip3 list | grep client
```

#### Install openstack client
```
pip install python-openstackclient python-heatclient
```

#### Get the openstack project rc file
1. Go to openstack, and under "Project" should be the heading "API Access" - click on it. 
2. On the far right of the page should be a button that says "Download Openstack RC File⬇"
3. Click on it and two options will drop down.
4. Click on "Openstack RC File" which will download a file name "\*-openrc.sh".
5. Copy that file into `image-processor/openstack`

#### Set the openstack project rc File variable

1. In `image-processor/openstack/openstack_upload.sh`, around line 3, change `project_rc_file` to be the filepath of the openstack rc file you have downloaded.

#### (optional) remove the openstack rc verification question
1. Go to the openstack project rc file and open it with an editor.
2. Delete lines 29 and 30.
3. On the new line 29, it should say `export OS_PASSWORD=$OS_PASSWORD_INPUT` 
4. Swap `$OS_PASSWORD_INPUT` for your openstack password.
5. Save and close the file.



## Running it

Run this:
```
bash dlimage.sh
```

After running, you will be asked a series of questions.

1. "s3 link for image raw file?" - What is the s3 link used to upload the image?
2. "What platform is the image going to be on?" - openstack/aws/azure
3. "What release candidate is this?" - release candidates should be named `rcx` where x is an integer abover 0
4. "What is the release date?" - the date of release in the format `dd.mm.yy`


After that, wait until the image is complete