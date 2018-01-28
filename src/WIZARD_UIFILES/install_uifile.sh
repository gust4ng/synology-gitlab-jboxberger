#!/bin/bash
# Copyright (c) 2000-2016 Synology Inc. All rights reserved.

PKG_NAME="GitLab"
BACKUP_CONFIG="/usr/syno/etc/packages/__PKG_NAME__/config"

NeedRestore()
{
	if [ -f "$BACKUP_CONFIG" ]; then
		return 0
	else
		return 1
	fi
}

GetDBName()
{
	get_key_value "$BACKUP_CONFIG" DB_NAME
}

GetDBUser()
{
	#version < "9.4.4-0050" does not store db_user in config
	DB_USER=$(get_key_value "$BACKUP_CONFIG" DB_USER)
	DB_USER=${DB_USER:-gitlab_user}
	echo "$DB_USER"
}

GetDBPass()
{
	get_key_value "$BACKUP_CONFIG" DB_PASS
}

GetShare()
{
	get_key_value "$BACKUP_CONFIG" SHARE
}

GetPkgVer()
{
	get_key_value "$BACKUP_CONFIG" PKG_VER
}
wizard_db_settings="Set up GitLab Database"
wizard_db_name_desc="Please enter the database name for GitLab."
wizard_db_name_label="Database name"
wizard_admin_acc="Account"
wizard_admin_pass="Password"
wizard_set_db_desc="Please create a new exclusive database account for GitLab to use existing/new data."
wizard_set_data_title="Set up GitLab"
wizard_found_backup="Please select a method to import data."
wizard_decide_restore="GitLab database already exists.<br>Please select either of the following actions:"
wizard_restore="Use existing data"
wizard_create_new="Clean install (All existing data, including configuration files and the database, will be removed.)"
wizard_db_user_account_desc="Database user account"
wizard_db_user_password_desc="Database user password"
install_title="Install GitLab"
install_data_root_desc="Create a shared folder to store the data of GitLab."
install_data_root_label="Shared folder name"
http_port_desc="Please enter the HTTP port number for GitLab."
http_port_label="HTTP port number"
ssh_port_desc="Please enter the SSH port number for GitLab."
ssh_port_label="SSH port number"
hostname_label="Domain name"
admin_email_desc="Please enter the GitLab administrator email account."
admin_email_label="email"
smtp_enable_desc="Enable GitLab to send emails through a SMTP server."
smtp_enable_label="Enable SMTP"
smtp_address_desc="Please enter the SMTP server address hosting GitLab."
smtp_address_label="SMTP address"
smtp_port_desc="Please enter the SMTP server port."
smtp_port_label="SMTP port"
smtp_user_desc="Please enter the SMTP server username."
smtp_user_label="SMTP username"
smtp_pass_desc="Please enter the SMTP server password."
smtp_pass_label="SMTP password"
smtp_verify_desc="When GitLab is connected, verify the SMTP server's SSL certificate."
smtp_verify_label="Verify the SSL certificate and refuse unsafe connections."
default_gitlab_account_desc="The default login credential is root/5iveL!fe"
PageRestore()
{
cat << EOF
{
	"step_title": "$wizard_found_backup",
	"items": [{
		"type": "singleselect",
		"desc": "$wizard_decide_restore",
		"subitems": [{
			"key": "restore_backup",
			"desc": "$wizard_restore",
			"defaultValue": true
		}, {
			"desc": "$wizard_create_new",
			"defaultValue": false
		}]
	}, {
		"type": "textfield",
		"subitems": [{
			"key": "worker_mode",
			"desc": "drop or skip",
			"defaultValue": "skip",
			"hidden": true
		}]
	}]
}
EOF
}

CheckRestore()
{
cat << EOF
// find constructor contains restore page
for (i = arguments[0].ownerCt.items.length-1; i >= 1; i--){
	page = arguments[0].ownerCt.items.items[i];
	if (page.headline === \"${wizard_found_backup}\"){
		// check whether user wants to restore or not
		restore = page.items.items[1].checked;
		break;
	}
}
EOF
}

FindObj()
{
cat << EOF
for (i = 0; i < arguments[0].items.length; i++) {
	item = arguments[0].items.items[i]
	if (\"${1}\" === item.itemId){
		$2 = arguments[0].items.items[i];
		break;
	}
}
EOF
}

Activate()
{
cat << EOF
	"activeate": "{
		restore = $DEFAULT_RESTORE; // user restore or not, set by is_restore
		// will set restore
		$(CheckRestore)

		if (arguments[0].headline === \"${wizard_db_settings}\") {
			create_db_multiselect = null;
			old_db_textfield= null;
			drop_db_multiselect= null;
			new_db_textfield = null;
			db_user_textfield = null;
			grant_user_multiselect = null;

			$(FindObj "create_db_flag" "create_db_multiselect")
			$(FindObj "pkgwizard_db_name" "new_db_textfield")
			$(FindObj "old_db_name" "old_db_textfield")
			$(FindObj "drop_db_flag" "drop_db_multiselect")
			$(FindObj "pkgwizard_db_user_account" "db_user_textfield")
			$(FindObj "grant_user_flag" "grant_user_multiselect")

			old_db = \"@OLD_DB@\";

			if (restore) {
				db_name = \"@OLD_DB@\";
				db_user = \"@OLD_USER@\";
			}
			else {
				db_name = \"gitlab\";
				db_user = \"gitlab_user\";
			}

			old_db_textfield.setValue(old_db);
			new_db_textfield.setValue(db_name);
			new_db_textfield.setDisabled(restore);
			db_user_textfield.setValue(db_user);

			create_db_multiselect.setVisible(false);
			drop_db_multiselect.setVisible(false);
			grant_user_multiselect.setVisible(false);

		}

		if (arguments[0].items.items[0].value === \"${install_data_root_desc}\") {
			dataroot_textfield = null;
			$(FindObj "pkgwizard_dataroot" "dataroot_textfield")
			if (restore) {
				dataroot_textfield.setValue(\"@OLD_DATAROOT@\");
			}
			dataroot_textfield.setDisabled(restore);
		}
	}",
EOF
}

Deactivate()
{
cat << EOF
	"deactivate": "{
		restore = $DEFAULT_RESTORE;
		$(CheckRestore) // if no radio button, will not set restore value
		if (arguments[0].headline === \"${wizard_db_settings}\") {
			create_db_multiselect = null;
			create_db_collision_textfield = null;
			old_db_textfield= null;
			drop_db_multiselect= null;
			new_db_textfield = null;
			grant_user_multiselect = null;

			$(FindObj "create_db_flag" "create_db_multiselect")
			$(FindObj "create_db_collision" "create_db_collision_textfield")
			$(FindObj "old_db_name" "old_db_textfield")
			$(FindObj "drop_db_flag" "drop_db_multiselect")
			$(FindObj "pkgwizard_db_name" "new_db_textfield")
			$(FindObj "grant_user_flag" "grant_user_multiselect")
			table = {
				\"5to10\": {\"migrate\": true, \"create\": false, \"grant_user\": true, \"drop_db\": true, \"create_db_collision\": \"error\"},
				\"restore10\": {\"migrate\": false, \"create\": true, \"grant_user\": true, \"drop_db\": false, \"create_db_collision\": \"skip\"},
				\"new10\": {\"migrate\": false, \"create\": true, \"grant_user\": true, \"drop_db\": old_db_textfield.rawValue && (old_db_textfield.rawValue !== new_db_textfield.rawValue)? true : false, \"create_db_collision\": old_db_textfield.rawValue === new_db_textfield.rawValue? \"replace\" : \"error\"}
			};

			if (restore) {
				state = \"restore10\";
			}
			else {
				state = \"new10\";
			}

			create_db_multiselect.setValue(table[state][\"create\"]);
			grant_user_multiselect.setValue(table[state][\"grant_user\"]);
			drop_db_multiselect.setValue(table[state][\"drop_db\"]);
			create_db_collision_textfield.setValue(table[state][\"create_db_collision\"]);
		}
}",
EOF
}

ApplyDBInfo()
{
	local page_db="$1"

	sed "s/@OLD_DB@/$DB_NAME/g;s/@OLD_USER@/$DB_USER/g;s/@OLD_DATAROOT@/$OLD_DATAROOT/g" <<< "$page_db"
}

PageDB()
{
	local page_db=$(cat << EOF
{
	"step_title": "$wizard_db_settings",
	$(Activate)
	$(Deactivate)
	"items": [{
		"type": "textfield",
		"desc": "$wizard_set_db_desc",
		"subitems": [{
			"key": "pkgwizard_db_name",
			"desc": "$wizard_db_name_label",
			"disabled": true,
			"validator": {
				"allowBlank": false
			}
		}]
	}, {
		"type": "textfield",
		"subitems": [{
			"indent": 1,
			"key": "pkgwizard_db_user_account",
			"desc": "$wizard_db_user_account_desc",
			"validator": {
				"allowBlank": false
			}
		}]
	}, {
		"type": "password",
		"subitems": [{
			"indent": 1,
			"key": "pkgwizard_db_user_password",
			"desc": "$wizard_db_user_password_desc"
		}]
	}, {
		"type": "textfield",
		"subitems": [{
			"key": "create_db_collision",
			"desc": "drop or skip",
			"defaultValue": "skip",
			"hidden": true
		}]
	}, {
		"type": "multiselect",
		"subitems": [{
			"key": "create_db_flag",
			"desc": "create db or not",
			"hidden": true
		}]
	}, {
		"type": "textfield",
		"subitems": [{
			"key": "old_db_name",
			"desc": "old db name",
			"hidden": true
		}]
	}, {
		"type": "multiselect",
		"subitems": [{
			"key": "drop_db_flag",
			"desc": "drop old db or not",
			"hidden": true
		}]
	}, {
		"type": "multiselect",
		"subitems": [{
			"key": "grant_user_flag",
			"desc": "must grant user if exist wizard",
			"defaultVaule": true,
			"hidden": true
		}]
	}]
}
EOF
)
	ApplyDBInfo "$page_db"
}
PageInstallSetting()
{
cat << EOF
{
	"step_title": "$install_title",
	"items": [{
		"type": "textfield",
		"desc": "$install_data_root_desc",
		"subitems": [{
			"key": "pkgwizard_dataroot",
			"desc": "$install_data_root_label",
			"defaultValue": "gitlab",
			"validator": {
				"allowBlank": false
			}
		}]
	},{
		"type": "textfield",
		"desc": "$http_port_desc",
		"subitems": [{
			"key": "pkgwizard_http_port",
			"desc": "$http_port_label",
			"defaultValue": "30000",
			"validator": {
				"allowBlank": false,
				"regex": {
					"expr": "/^[1-9]\\\\d{0,4}$/"
				}
			}
		}]
	},{
		"type": "textfield",
		"desc": "$ssh_port_desc",
		"subitems": [{
			"key": "pkgwizard_ssh_port",
			"desc": "$ssh_port_label",
			"defaultValue": "30001",
			"validator": {
				"allowBlank": false,
				"regex": {
					"expr": "/^[1-9]\\\\d{0,4}$/"
				}
			}
		}]
	}]
},{
	"step_title": "$install_title",
	"items": [{
		"type": "textfield",
		"desc": "$hostname_desc",
		"subitems": [{
			"key": "pkgwizard_hostname",
			"desc": "$hostname_label",
			"defaultValue": "localhost",
			"validator": {
				"allowBlank": false
			}
		}]
	},{
		"type": "textfield",
		"desc": "$admin_email_desc",
		"subitems": [{
			"key": "pkgwizard_admin_email",
			"desc": "$admin_email_label",
			"defaultValue": "example@example.com",
			"validator": {
				"allowBlank": false,
				"vtype": "email"
			}
		}]
	}]
},{
	"step_title": "$install_title",
	"items": [{
		"type": "multiselect",
		"desc": "$smtp_enable_desc",
		"subitems": [{
			"key": "pkgwizard_smtp_enable",
			"desc": "$smtp_enable_label",
			"defaultValue": false
		}]
	},{
		"type": "textfield",
		"desc": "$smtp_address_desc",
		"subitems": [{
			"key": "pkgwizard_smtp_address",
			"desc": "$smtp_address_label"
		}]
	},{
		"type": "textfield",
		"desc": "$smtp_port_desc",
		"subitems": [{
			"key": "pkgwizard_smtp_port",
			"desc": "$smtp_port_label",
			"defaultValue": "587",
			"validator": {
				"allowBlank": false,
				"regex": {
					"expr": "/^[1-9]\\\\d{0,4}$/"
				}
			}
		}]
	},{
		"type": "textfield",
		"desc": "$smtp_user_desc",
		"subitems": [{
			"key": "pkgwizard_smtp_user",
			"desc": "$smtp_user_label"
		}]
	},{
		"type": "password",
		"desc": "$smtp_pass_desc",
		"subitems": [{
			"key": "pkgwizard_smtp_pass",
			"desc": "$smtp_pass_label"
		}]
	},{
		"type": "multiselect",
		"desc": "$smtp_verify_desc",
		"subitems": [{
			"key": "pkgwizard_smtp_verify",
			"desc": "$smtp_verify_label",
			"defaultValue": true
		}]
	}]
},{
	"step_title": "$install_title",
	"items": [{
		"desc": "$default_gitlab_account_desc"
	}]
}
EOF
}
main()
{
	local install_page=""

	DEFAULT_RESTORE=false
	DB_NAME="$(GetDBName)"
	DB_USER="$(GetDBUser)"
	OLD_DATAROOT="$(GetShare)"

	if NeedRestore; then
		install_page="$(PageRestore),$(PageInstallSetting),$(PageDB)"
	else
		install_page="$(PageInstallSetting),$(PageDB)"
	fi

	echo "[$install_page]" > "${SYNOPKG_TEMP_LOGFILE}"

	return 0
}

main "$@"

