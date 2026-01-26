
@frappe.whitelist()
def get_tasks(search_text=None, status=None, priority=None):
    try:
        user = frappe.session.user
        if user == "Guest":
            return {"status": "error", "message": _("Authentication required")}

        roles = frappe.get_roles(user)
        is_admin_or_hr = any(role in ["System Manager", "Administrator", "HR Manager", "HR User"] for role in roles)

        filters = []
        or_filters = []

        # 1. Base Filter (Role Based)
        # If not Admin/HR, user sees tasks where they are Owner OR Assigned To
        if not is_admin_or_hr:
            # owner is the creator (owner field). 
            # assigned_to is a Link User field (as per user request: "Assigned To assigned_to Link (User)")
            # Standard Task doctype uses '_assign' (todo) for assignments usually, but user specified 'assigned_to'.
            # I will check if 'assigned_to' is a standard field or custom.
            # Standard Task has 'owner' (creator).
            # It implies we need to check both owner and 'assigned_to'.
            
            # Using complex query logic because mixing AND with OR group in get_list is tricky.
            # but we can try simple filters if possible.
            # Let's assume we can filter by 'owner' OR 'assigned_to'
            # or_filters = [["owner", "=", user], ["assigned_to", "=", user]]
            pass 

        # 2. Search Filter
        if search_text:
            filters.append(["subject", "like", f"%{search_text}%"])
        
        # 3. Status Filter
        if status and status != "All":
            filters.append(["status", "=", status])

        # 4. Priority Filter
        if priority and priority != "All":
            filters.append(["priority", "=", priority])
            
        # Execute Query
        # We need custom logic for the OR condition if not admin
        
        if is_admin_or_hr:
             tasks = frappe.get_list(
                "Task",
                filters=filters,
                fields=["name", "subject", "status", "priority", "exp_start_date", "exp_end_date", "description", "owner", "assigned_to"],
                order_by="exp_end_date asc",
                limit_page_length=100
            )
        else:
            # User specific: (Owner = User OR Assigned To = User) AND (Other filters)
            # Frappe OR filters apply to the main query logic.
            # filters AND (or_filters)
            
            user_filters = [
                ["owner", "=", user],
                ["assigned_to", "=", user]
            ]
            
            tasks = frappe.get_list(
                "Task",
                filters=filters,
                or_filters=user_filters,
                fields=["name", "subject", "status", "priority", "exp_start_date", "exp_end_date", "description", "owner", "assigned_to"],
                order_by="exp_end_date asc",
                limit_page_length=100
            )

        return {
            "status": "success", 
            "message": "Tasks fetched successfully",
            "data": tasks
        }

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Tasks API Error")
        return {"status": "error", "message": str(e)}
