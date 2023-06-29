# Salesforce Org Auditor

Salesforce Org Auditor - monitor and report on changes to your orgs


## Key features:
- Retrieve and track Setup Audit Log from any SF Org
- Load this load into any SF Org for analysis, monitoring and reporting.
- 
- 

## Potential future enhancements
- Run periodically
- Send email alerts on unauthorised changes
- Integrate notifications into Slack

## How to Install


#### Prerequisites
* You need the **SFDX CLI tool** installed on your machine

Note: you do _not_ require access to a SFDX DevHub to install this component, just the SFDX CLI tool installed.  
Go here if you haven't already installed SFDX: https://developer.salesforce.com/tools/sfdxcli  

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

For ORG_NAME, you provide an alias that gets assigned for the org you login to.  
You will use this to reference the org in subsequent commands.  

#### Step 3: Deploy the package to your org
```
sfdx project:deploy:start -o ORG_NAME
```


## Post-Install Configuration


#### Step 1: Provide user access via Permission Set

* Run script:
```
scripts/shell/assign-perm-sets.sh -o ORG_NAME
```

* Or via Salesforce Setup:
    * Open your org
    * Go to Setup > Users > Permission Sets
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

### Done!



## How to Use

* Run script
```
scripts/shell/get-upsert-trail.sh --source SOURCE_ORG_NAME -o ORG_NAME
```



## How to contribute to this module

#### Prerequisites
* You need the **SFDX CLI tool installed** on your machine
* You need to have a **Dev Hub authorised** on your machine

