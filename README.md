# aldm-ecosystem
###  Preparing the build system for use
* Checkout the aldm-ecosystem git tree
  * Recommended location:
    - ~/ALDM/CODE\_BUILD/ALDM2.0/

* Install your git ssh keys in your home directory 
  * Recommended location:
    - ~/.ssh/GIT/
* Edit the construct.cfg file to reflect you git key names, or rename the keys the same as in the cfg

* Execute the following commands to setup the OS and install the locak dependecies 

  * Copy the dependencies file into the locak directory or a directory named /var/lib/docker/aldm location:
    - cp <sourcedir>/dependencies.tgz .
  * ./instance\_install.sh PREINSTALL DEVELOP
  * ./instance\_install.sh dirs 
  * ./instance\_install.sh DOCKERSTART 

### The ALDM-ECOSYSTEM consists of the following applications and/or containers by the same name

* Producers \(discover, analyze and generate data\) 

  * aldm-collectors
  * aldm-pipeline
  * dce-pipeline

* Presenters \(query, change or present data\)
  
  * dce-webapp
  * dce-graphql
  
  ALDM1.0 \(only\)
  * aldm-webportal

  ALDM2.0 \(only\)
  * aldm-ui
  * aldm-api
  * couchdb

* Managers \(store data\)
  
  * mariadb

  ALDM1.0 
  * derby
  ALDM2.0 
  * couchdb

### Using the  ALDM-ECOSYSTEM 
* Instructions for use of the construct.sh scripts

1. clone or download the aldm-ecosystem repository
2. edit the construct.cfg file for your suit your local environment, in most cases you will not need to change the ID,URL or REPO location
   
	> LOCAL_REPO_ROOT=\"$HOME/ALDM/CODE_build/ALDM2.0\"  # the root of where you start your builds and git repo clones <br>
    > ID=        #  your git id \(typically git@github.ibm.com\) <br>
	> URL=       #  the URL of the git repository <br>
	> REPO=      #  the shortname of the git repo \(i.e. owner/repo\) <br>
	> DIR=       #  the full path name of the directory after the the repo is cloned <br>
	> SRC=       #  the full path name of the dir/sub-directory where the actual building occurs \(may be same as DIR\) <br>
	> KEY=       #  your git SSHKEY for your ID@REPO <br>
   
3.   Run the construct.sh command

	Usage: construct.sh container_name build|image|push
		container_name clone 
		container_name status 
		container_name gitpush             

   build operations:
   
	build	-- builds or compliles the application source code and prepares for a docker image build
	image	-- builds the docker image itself, requires root level access on the local system, requires docker-ce or
      		      an equivalent container enviornment to be installed and running
	push 	-- pushes the built docker image to the Artifactory repository

   git operations:
   
	clone 	-- clones the source code from the git repository 
	status 	-- shows status of both the local and remote git repository 
	gitpush -- pushes the local git repository commits to the remote git repository
     
A.   a list of currently available container builds

	Usage: construct.sh container_name build|image|push|clone|status|gitpush
	
       	containers:

		dce-pipeline 
		dce-graphql 
		dce-webapp 
		aldm-ui 
		aldm-api 
		aldm-help 
		aldm-webportal 
		aldm-pipeline 
		mariadb 
		derby  
	
B.   an additional list of available sources

       Usage: construct.sh container_name clone|status|gitpush
       
       sources:
		aldm-ecosystem
		aldm-scripts 
