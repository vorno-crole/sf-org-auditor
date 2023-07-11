# Salesforce Org Auditor

Salesforce Org Auditor - monitor and report on unauthorised changes to your orgs  



## Key features:
- Retrieve and track Setup Audit Log from any SF Org
- Load this load into any SF Org for analysis, monitoring and reporting.
- 
- 

## Potential future enhancements
- Sometimes bug: Some CSV lines are flat out duplicates (same D/T, same content)
- Run periodically
- Send email alerts on unauthorised changes
- Integrate notifications into Slack

<p><br/></p>

## How to Install


#### Prerequisites
* You need the **SFDX CLI tool** installed on your machine
* You need **Git** installed on your machine
* You need to have an **org ready to install into**

#### Step 1: Clone this repository

```
git clone https://github.com/vorno-crole/sf-org-auditor.git
cd sf-org-auditor
```

#### Step 2: Authenticate your org in SFDX
```
sfdx auth:web:login -a ORG_NAME
```

For *ORG_NAME*, you provide an alias that gets assigned for the org you login to.  
You will use this to reference the org in subsequent commands.  

#### Step 3: Deploy the package to your org
```
sfdx project:deploy:start -o ORG_NAME
```

<p><br/></p>

## Post-Install Configuration


#### Step 1: Provide user access via Permission Set

* Run script:
```
scripts/shell/assign-perm-sets.sh -o ORG_NAME
```

* Or via Salesforce Setup:
    * Open your org
    * Go to Setup > Users > **Permission Sets**
    * Open the `SF Org Auditor` Permission Set
    * Click **Manage Assignments**
    * Click **Add Assignments**
    * **Tick one or many users** you wish to allow access
    * Click **Assign**


#### Step 2: Import Data

* Run script:
```
data/import-all.sh -o ORG_NAME
```


#### Step 3: Review the Audit Log rules

* Open your org
* Ensure you are in the **Org Auditor** app
* Open the **Audit Rules** tab, select **All** list view
* Add, change or remove rules as required.

Note: You will probably want to do this step continuously, as your logs are loaded and you review and tune Org Auditor to allow or deny different log items.

<p><br/></p>

## How to Use


#### Step 1: Import Setup Audit Log from the org you wish to monitor

* Run script
```
scripts/shell/get-upsert-trail.sh --source SOURCE_ORG_NAME -o ORG_NAME
```
*SOURCE_ORG_NAME* is the org you wish to monitor  
*ORG_NAME* is the org you installed into and will monitor the changes from  

#### Step 2: Monitor the changes in your reporting org

* Open your org
* Ensure you are in the **Org Auditor** app
* Open the **Dashboards** tab
* Click on **All Folders**, then open the **Auditor Dashboards** folder
* Open the **Auditor Dashboard**


<p><br/></p>

## How to contribute to this module

#### Prerequisites
* You need the **SFDX CLI tool installed** on your machine
* You need to have a **Dev Hub authorised** on your machine

