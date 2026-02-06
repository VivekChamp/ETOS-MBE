import frappe
import requests
import json

def send_fcm_notification(user, title, body, data=None):
    """
    Sends an FCM notification to a specific user's registered devices.
    """
    # Get FCM Server Key from site_config
    fcm_server_key = frappe.conf.get("fcm_server_key")
    if not fcm_server_key:
        frappe.log_error("FCM Server Key not found in site_config.json", "Notification Error")
        return

    # Get device tokens for the user
    tokens = frappe.get_all("User Device Token", 
                            filters={"user": user}, 
                            pluck="device_token")
    
    if not tokens:
        return

    url = "https://fcm.googleapis.com/fcm/send"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"key={fcm_server_key}"
    }

    for token in tokens:
        if not token: continue
        
        payload = {
            "to": token,
            "notification": {
                "title": title,
                "body": body,
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
                "sound": "default"
            },
            "data": data or {}
        }

        try:
            response = requests.post(url, headers=headers, data=json.dumps(payload), timeout=10)
            if response.status_code != 200:
                frappe.log_error(f"FCM response error: {response.text}", "Notification Error")
        except Exception as e:
            frappe.log_error(frappe.get_traceback(), "FCM Send Exception")

def on_todo_update(doc, method=None):
    """
    Hook function called when a ToDo is created or updated.
    ToDo is used for Assignments in Frappe.
    """
    # Only notify for new assignments (ToDo items)
    if doc.flags.notified:
        return

    if doc.allocated_to:
        title = "New Task Assigned"
        # Handle cases where reference_type might not be Task
        ref_type = doc.reference_type or "Task"
        ref_name = doc.reference_name or doc.name
        
        body = f"You have been assigned a new {ref_type}: {doc.description or ref_name}"
        
        send_fcm_notification(
            user=doc.allocated_to,
            title=title,
            body=body,
            data={
                "doctype": ref_type,
                "docname": ref_name,
                "todo_id": doc.name
            }
        )
        doc.flags.notified = True
