# servchal
This is a repo created to submit my code and solution for a technical challenge. Below is the architecuture of the infra provisioned using terraform. The deployment code for the application will be added shortly. The application is set to run on 2 availability zones with loadbalancing. App is set to run as a Linux service which will attempt to restart in case of failiure. The /debug directory access has been limited to the internal environment for security reasons. It could be accessed from http://localhost:3000/debug after login in to the appserver.
![image](https://user-images.githubusercontent.com/19792463/221649882-8d635ed6-04ee-4fde-8a80-ee64ba4dfd89.png)

# Prerequisites
Need to update the ansible/artefacts/conf.toml file with database parameters. The name and the password needs to be updated in the infra/variables.tf file as well. Please choose a db name that is non-existant and a strong password. If not it will fail.

# How to run
This needs to be done in a semi-automated fasion as the AzureDevOps pipeline written has issues connecting in the ansible steps as mentioned later in this Readme. 
1. Clone the repo to your local machine.
2. Replace the identity files key pairs with similar names. (Since only the public key is available in the repo).
3. Follow the steps in the prerequisites above.
4. Do a terraform init from the infra/ folder.
5. If all looks good, do a terraform plan. Followed by a terraform apply and provide approval when prompted. This should create the resources.
6. Once the resource creation is done, go to the ansible/ directory and update the inventory file add the following lines.
      [jumphosts]
      <public IP of the jumphost found in the file generated in infra/ directory>
7. Next update the ansible.cfg file in ansible with the following entry 
      ansible_ssh_private_key_file=<path to the key file of the jumphost>
8. Now run the setup host playbook from the ansible/ directory. 
      ansible-playbook setupjump.yml
9. Once that is done, log in and clone the repo to the jumphost. Replace the identity files with that of the appservers. Get the private ips from the files generated in the infra/ directory of your local machine and add them under the [appservers] section of the inventory file in the jumphost. 
10. Update the ansible.cfg file with the path to the identity file in the jumphost.
        ansible_ssh_private_key_file=<path to the key file of the appservers>
11. Execute the playbook in ansible/ directory.
    ansible-playbook playbook.yml

# How I wanted it to work
I have written an azure DevOps pipeline that partially works. There is an issue with the ansible steps in connecting with the remote hosts. Which I need to debug. If not for that I belive it would work completely fine. At the time of writing this, infra provisioning and setting up the jumphosts(until the playbook job works fine).

How to setup the azure devops project.
1. Create a repo in GitHub with this repo.
2. Create an Azure DevOps organization and project. Next create a yaml pipeline and select the repo that you created. Authenticate when required. Here when prompted to select the yaml click on existing and select the yaml file in the repo.![AzureDevOpsSelectPipeline](https://user-images.githubusercontent.com/19792463/222588826-070ee495-cc5b-4a5f-941c-812b820a71ab.png)

3. Once the pipeline is created there is a dependency that needs to be installed. While logged in to Azure DevOps, open https://marketplace.visualstudio.com/items?itemName=charleszipp.azure-pipelines-tasks-terraform and click on Get it free. Install it for Azure DevOps.
4. Next we need to import the secrets for that import our key files to our library group it needs to be named as in the following screenshot. ![image](https://user-images.githubusercontent.com/19792463/222590077-52bbfb76-2f70-48e7-943b-b657c2940cf7.png)
After creating them, upload the secret key file there and grant permissions to the pipeline created. Once done, we should be good to go. Refer https://learn.microsoft.com/en-us/azure/devops/pipelines/library/secure-files?view=azure-devops for more info.
