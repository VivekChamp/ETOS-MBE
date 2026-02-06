import frappe
from frappe import _
from frappe.utils import nowdate
import re
from html import unescape


# def clean_html(text):
#     """Remove HTML tags and clean text for mobile display"""
#     if not text:
#         return ""
#     # Remove HTML tags
#     text = re.sub(r'<[^>]+>', '', text)
#     # Unescape HTML entities
#     text = unescape(text)
#     # Remove extra whitespace
#     text = ' '.join(text.split())
#     return text.strip()


# @frappe.whitelist(allow_guest=True)
# def login(usr, pwd):
#     try:
#         login_manager = frappe.auth.LoginManager()
#         login_manager.authenticate(usr, pwd)
#         login_manager.post_login()

#         # Fetch user doc
#         user_doc = frappe.get_doc("User", frappe.session.user)

#         # Get all roles for the logged in user (excluding "All")
#         roles = frappe.get_roles(frappe.session.user)
#         roles = [r for r in roles if r != "All"]

#         # Fetch Linked Employee
#         employee_details = frappe.db.get_value(
#             "Employee", 
#             {"user_id": frappe.session.user}, 
#             ["name", "employee_name", "image", "designation", "department"],
#             as_dict=True
#         )

#         frappe.response["message"] = "Logged In"
#         frappe.response["first_name"] = user_doc.first_name
#         frappe.response["sid"] = frappe.session.sid
#         frappe.response["roles"] = roles
        
#         # Add Employee Info to Response
#         if employee_details:
#              frappe.response["employee_info"] = employee_details
#         else:
#              frappe.response["employee_info"] = None

#         # Chart visibility logic (Example logic based on your request)
#         allowed_chart_roles = ["Kmcc Constituency Admin", "Kmcc District Admin", "Administrator", "Admin"]
#         frappe.response["show_chart"] = any(role in allowed_chart_roles for role in roles)

#     except frappe.AuthenticationError:
#         frappe.clear_messages()
#         frappe.response["message"] = "Invalid username or password"
#         frappe.response["error"] = True

#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Mobile Login Error")
#         frappe.response["message"] = "An error occurred during login"
#         frappe.response["error"] = str(e)

# @frappe.whitelist()
# def get_logged_in_user_info():
#     try:
#         if frappe.session.user == "Guest":
#             return {"status": "error", "message": "User not logged in"}

#         user = frappe.session.user

#         # Get user full name
#         full_name = frappe.db.get_value("User", user, "full_name")

#         # Check linked employee
#         employee_id = frappe.db.get_value("Employee", {"user_id": user}, "name")

#         return {
#             "status": "success",
#             "user": {
#                 "user_id": user,
#                 "full_name": full_name,
#                 "employee_id": employee_id
#             }
#         }

#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get Logged-in User Info API Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def get_project_names(search_text=None, status=None, from_date=None, to_date=None):
#     """
#     Fetch projects where the logged-in user is involved, with optional filters.
#     Returns projects where user is the owner, project manager, or assigned as a team member.
    
#     Filters: search_text, status, from_date, to_date
#     """
#     try:
#         user = frappe.session.user
#         if user == "Guest":
#             return {"status": "error", "message": _("Authentication required")}

#         roles = frappe.get_roles(user)
#         is_admin = any(role in ["System Manager", "Administrator", "Projects Manager"] for role in roles)

#         if is_admin:
#             # Admin: Get all active projects with filters
#             filters = {"status": ["!=", "Cancelled"]}
            
#             # Apply search filter
#             if search_text:
#                 filters["project_name"] = ["like", f"%{search_text}%"]
            
#             # Apply status filter
#             if status and status != "All":
#                 filters["status"] = status
            
#             # Apply date filters
#             if from_date:
#                 if "creation" not in filters:
#                     filters["creation"] = []
#                 filters["creation"].append([">=", from_date])
#             if to_date:
#                 if "creation" not in filters:
#                     filters["creation"] = []
#                 filters["creation"].append(["<=", to_date])
            
#             projects = frappe.get_all(
#                 "Project",
#                 filters=filters,
#                 fields=["name", "project_name", "status", "project_type", "is_active", 
#                         "percent_complete_method", "expected_start_date", "expected_end_date", 
#                         "priority", "percent_complete"],
#                 order_by="creation desc"
#             )
#         else:
#             # Get projects where user is involved (owner, or team member) with filters
#             # Using SQL to check Project Users child table
#             project_list = frappe.db.sql("""
#                 SELECT DISTINCT p.name, p.project_name, p.status, p.project_type, 
#                        p.is_active, p.percent_complete_method, p.expected_start_date, 
#                        p.expected_end_date, p.priority, p.percent_complete
#                 FROM `tabProject` p
#                 LEFT JOIN `tabProject User` pu ON pu.parent = p.name AND pu.user = %(user)s
#                 WHERE (p.owner = %(user)s OR pu.user = %(user)s)
#                   AND p.status != 'Cancelled'
#                   {search_condition}
#                   {status_condition}
#                   {from_date_condition}
#                   {to_date_condition}
#                 ORDER BY p.creation DESC
#                 LIMIT 100
#             """.format(
#                 search_condition=f"AND p.project_name LIKE '%{search_text}%'" if search_text else "",
#                 status_condition=f"AND p.status = '{status}'" if status and status != "All" else "",
#                 from_date_condition=f"AND p.creation >= '{from_date}'" if from_date else "",
#                 to_date_condition=f"AND p.creation <= '{to_date}'" if to_date else ""
#             ), {"user": user}, as_dict=True)
            
#             projects = project_list

#         return {
#             "status": "success",
#             "message": f"Found {len(projects)} projects",
#             "projects": projects
#         }
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get Project Names Error")
#         return {
#             "status": "error",
#             "message": str(e)
#         }

# @frappe.whitelist()
# def get_leads(search_text=None, status=None, from_date=None, to_date=None):
#     try:
#         if frappe.session.user == "Guest":
#             return {"status": "error", "message": _("Authentication required")}

#         user_email = frappe.session.user
        
#         # Build filter conditions
#         conditions = []
        
#         # Search Filter (Lead Name, Company, Email)
#         if search_text:
#             conditions.append(f"(l.lead_name LIKE '%{search_text}%' OR l.company_name LIKE '%{search_text}%' OR l.email_id LIKE '%{search_text}%')")

#         # Status Filter
#         if status and status != "All":
#             conditions.append(f"l.status = '{status}'")

#         # Date Filter
#         if from_date:
#             conditions.append(f"l.creation >= '{from_date}'")
#         if to_date:
#             conditions.append(f"l.creation <= '{to_date}'")
            
#         where_clause = " AND ".join(conditions)
#         if where_clause:
#             where_clause = " AND " + where_clause

#         # User permission filter: Owner, Email match, OR Assigned via ToDo
#         permission_condition = ""
#         if user_email != "Administrator":
#              permission_condition = """
#                 AND (
#                     l.lead_owner = %(user)s 
#                     OR l.email_id = %(user)s 
#                     OR t.name IS NOT NULL
#                 )
#              """

#         # SQL Query to fetch Lead Names
#         query = f"""
#             SELECT DISTINCT l.name
#             FROM `tabLead` l
#             LEFT JOIN `tabToDo` t ON t.reference_name = l.name AND t.reference_type = 'Lead' AND t.allocated_to = %(user)s
#             WHERE l.name IS NOT NULL
#             {permission_condition}
#             {where_clause}
#             ORDER BY l.creation DESC
#             LIMIT 100
#         """

#         lead_names = frappe.db.sql(query, {"user": user_email}, as_dict=True)

#         leads = []
#         for lead_entry in lead_names:
#             lead_doc = frappe.get_doc("Lead", lead_entry.name)

#             leads.append({
#                 "name": lead_doc.name,
#                 "lead_name": lead_doc.lead_name,
#                 "lead_owner": lead_doc.lead_owner,
#                 "status": lead_doc.status,
#                 "source": lead_doc.source,
#                 "type": lead_doc.type,
#                 "request_type": lead_doc.request_type,
#                 "gender": lead_doc.gender,
#                 "phone": lead_doc.phone,
#                 "mobile_no": lead_doc.mobile_no,
#                 "company_name": lead_doc.company_name,
#                 "annual_revenue": lead_doc.annual_revenue,
#                 "industry": lead_doc.industry,
#                 "market_segment": lead_doc.market_segment,
#                 "territory": lead_doc.territory,
#                 "city": lead_doc.city,
#                 "country": lead_doc.country,
#                 "open_activities_html": lead_doc.get("open_activities_html"),
#                 "all_activities_html": lead_doc.get("all_activities_html"),
#                 "notes": [
#                     {
#                         "note": clean_html(n.note) if n.note else "",
#                         "added_by": n.added_by,
#                         "added_on": n.added_on
#                     }
#                     for n in lead_doc.notes
#                 ]
#             })

#         return {
#             "status": "success",
#             "message": "Leads fetched successfully with activities",
#             "leads": leads
#         }
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get Leads Error")
#         return {
#             "status": "error",
#             "message": str(e)
#         }

# @frappe.whitelist()
# def assign_lead(lead_id, assign_to_users, priority="Medium", complete_by=None, comment=None):
#     try:
#         from frappe.desk.form.assign_to import add as add_assignment
        
#         if isinstance(assign_to_users, str):
#             import json
#             try:
#                 assign_to_users = json.loads(assign_to_users)
#             except:
#                 assign_to_users = [assign_to_users]
                
#         if not assign_to_users:
#              return {"status": "error", "message": "No users selected for assignment"}
             
#         for user in assign_to_users:
#             args = {
#                 "assign_to": [user],
#                 "doctype": "Lead",
#                 "name": lead_id,
#                 "description": comment or f"Assigned by {frappe.session.user}",
#                 "priority": priority
#             }
#             if complete_by:
#                 args['date'] = complete_by
                
#             add_assignment(args)
            
#         return {"status": "success", "message": "Lead assigned successfully"}
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Assign Lead Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def get_lead_assignments(lead_id):
#     """
#     Get all users assigned to a specific lead.
#     Returns list of assigned users with their assignment details.
#     """
#     try:
#         if frappe.session.user == "Guest":
#             return {"status": "error", "message": _("Authentication required")}
        
#         # Get ToDo records for this lead
#         assignments = frappe.get_all(
#             "ToDo",
#             filters={
#                 "reference_type": "Lead",
#                 "reference_name": lead_id,
#                 "status": ["!=", "Cancelled"]
#             },
#             fields=["name", "allocated_to", "description", "priority", "date", "status"],
#             order_by="creation desc"
#         )
        
#         return {
#             "status": "success",
#             "data": assignments,
#             "count": len(assignments)
#         }
        
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get Lead Assignments Error")
#         return {"status": "error", "message": str(e)}


# @frappe.whitelist()
# def create_lead(lead_name, mobile_no, email_id=None, company_name=None):
#     """
#     Creates a new Lead in ERPNext.
#     """
#     try:
#         new_lead = frappe.new_doc("Lead")
#         new_lead.first_name = lead_name
#         new_lead.mobile_no = mobile_no
#         new_lead.email_id = email_id
#         new_lead.company_name = company_name
#         new_lead.lead_owner = frappe.session.user
#         new_lead.status = "Lead"
#         new_lead.save()
#         return {"status": "success", "message": "Lead created successfully", "data": new_lead.name}
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Create Lead Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def get_lead_connections(lead_name):
#     try:
#         if not frappe.db.exists("Lead", lead_name):
#             return {"status": "error", "message": "Lead does not exist."}

#         # Get linked Opportunities
#         opportunities = frappe.get_all("Opportunity", filters={"party_name": lead_name, "opportunity_from": "Lead"}, fields=["name"])

#         # Get linked Quotations
#         quotations = frappe.get_all("Quotation", filters={"party_name": lead_name}, fields=["name"])

#         # Get linked Prospects
#         prospects = frappe.get_all("Prospect", filters={"lead": lead_name}, fields=["name"])

#         return {
#             "status": "success",
#             "opportunities": opportunities,
#             "quotations": quotations,
#             "prospects": prospects
#         }

#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get Lead Connections Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def get_sales_person():
#     try:
#         current_user = frappe.session.user

#         if current_user == "Guest":
#             return {"status": "error", "message": _("Login required")}

#         roles = frappe.get_roles(current_user)

#         # Admin / Manager shows all sales persons
#         if "Sales Manager" in roles or "System Manager" in roles:
#             sales_persons = frappe.get_all(
#                 "Sales Person",
#                 fields=["name", "sales_person_name"]
#             )
#             return {"status": "success", "data": sales_persons}

#         # For Sales Person role -> show only linked one
#         else:
#             # Find Sales Person linked to user
#             sales_person_doc = frappe.db.get_value(
#                 "Sales Person",
#                 {"custom_user": current_user},
#                 ["name", "sales_person_name"],
#                 as_dict=True
#             )

#             if sales_person_doc:
#                 return {"status": "success", "data": [sales_person_doc]}
#             else:
#                 return {"status": "error", "message": _("No Sales Person linked to user")}

#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "get_sales_person API Error")
#         return {"status": "error", "message": str(e)}


# @frappe.whitelist()
# def get_employee_list_with_user():
#     """
#     Fetches a list of all Employees who are linked to a system User.
#     Returns their Employee ID ('name') and Full Name ('employee_name').
#     """
#     try:
#         if frappe.session.user == "Guest":
#             return {
#                 "status": "error",
#                 "message": _("Authentication required.")
#             }

#         employees = frappe.get_all(
#             "Employee",
#             filters={"user_id": ["!=", ""]},
#             fields=["name", "employee_name"],
#             order_by="employee_name asc"
#         )

#         return {"status": "success", "data": employees}

#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get Employee List with User API Error")
#         return {
#             "status": "error",
#             "message": str(e)
#         }

# # ----------------- TASKS MODULE (Added based on requirements) -----------------

# @frappe.whitelist()
# def get_my_tasks():
#     """
#     Fetch tasks assigned to the current user or created by them.
#     Using standard 'Task' doctype.
#     """
#     try:
#         if frappe.session.user == "Guest":
#             return {"status": "error", "message": _("Authentication required")}
            
#         tasks = frappe.get_all(
#             "Task",
#             filters=[
#                 ["status", "!=", "Cancelled"],
#                 ["_assign", "like", f"%{frappe.session.user}%"]
#             ],
#             fields=["name", "subject", "status", "priority", "exp_end_date", "description", "project"],
#             order_by="exp_end_date asc"
#         )
        
#         # Clean HTML from descriptions
#         for task in tasks:
#             if task.get('description'):
#                 task['description'] = clean_html(task['description'])
        
#         return {"status": "success", "data": tasks}
        
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get My Tasks Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def create_task(subject, description, date, priority="Medium", assign_to=None):
#     try:
#         new_task = frappe.new_doc("Task")
#         new_task.subject = subject
#         new_task.description = description
#         new_task.exp_end_date = date
#         new_task.priority = priority
#         new_task.save()
        
#         # Handle assignments if provided
#         assigned_to_users = []
#         if assign_to:
#             import json
#             # Parse if string/JSON
#             if isinstance(assign_to, str):
#                 try:
#                     assign_to = json.loads(assign_to)
#                 except:
#                     assign_to = [assign_to]
            
#             # Ensure list
#             if not isinstance(assign_to, list):
#                 assign_to = [assign_to]
                
#             # Use assignment API logic
#             from frappe.desk.form.assign_to import add as add_assignment
            
#             for user in assign_to:
#                 try:
#                     add_assignment({
#                         "assign_to": [user],
#                         "doctype": "Task",
#                         "name": new_task.name,
#                         "description": f"Assigned upon creation by {frappe.session.user}",
#                         "priority": priority,
#                         "date": date
#                     })
#                     assigned_to_users.append(user)
#                 except Exception as e:
#                     frappe.log_error(f"Failed to assign to {user}: {str(e)}")

#         # If no explicit assignment, can we auto-assign to creator? 
#         # Requirement says "assign to users", so only if requested.
        
#         return {
#             "status": "success", 
#             "message": "Task created successfully", 
#             "data": new_task.name,
#             "assigned_to": assigned_to_users
#         }
        
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Create Task Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def update_task_status(task_id, status):
#     """
#     Update status of a task (e.g., Open, Completed)
#     """
#     try:
#         task = frappe.get_doc("Task", task_id)
#         task.status = status
#         task.save()
#         return {"status": "success", "message": "Task status updated"}
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Update Task Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def get_tasks(search_text=None, status=None, priority=None):
#     """
#     Fetch tasks assigned to the logged-in user.
#     Returns tasks where user is the owner OR assigned to the task.
#     This acts as a TODO list for the user.
#     """
#     try:
#         user = frappe.session.user
#         if user == "Guest":
#             return {"status": "error", "message": _("Authentication required")}

#         roles = frappe.get_roles(user)
#         is_admin = any(role in ["System Manager", "Administrator"] for role in roles)

#         # Build base filters
#         filters = {"status": ["!=", "Cancelled"]}

#         # Search Filter
#         if search_text:
#             filters["subject"] = ["like", f"%{search_text}%"]
        
#         # Status Filter
#         if status and status != "All":
#             filters["status"] = status

#         # Priority Filter
#         if priority and priority != "All":
#             filters["priority"] = priority

#         # For non-admin users, filter by assigned tasks using SQL
#         if not is_admin:
#             # Get tasks where user is in _assign field (JSON field storing assigned users)
#             # OR where user is the owner
#             task_list = frappe.db.sql("""
#                 SELECT DISTINCT t.name, t.subject, t.status, t.priority, 
#                        t.exp_start_date, t.exp_end_date, t.description, 
#                        t.owner, t.project
#                 FROM `tabTask` t
#                 LEFT JOIN `tabToDo` td ON td.reference_type = 'Task' 
#                     AND td.reference_name = t.name 
#                     AND td.allocated_to = %(user)s
#                 WHERE (t.owner = %(user)s OR td.allocated_to = %(user)s)
#                   AND t.status != 'Cancelled'
#                   {search_condition}
#                   {status_condition}
#                   {priority_condition}
#                 ORDER BY t.exp_end_date ASC
#                 LIMIT 100
#             """.format(
#                 search_condition=f"AND t.subject LIKE '%{search_text}%'" if search_text else "",
#                 status_condition=f"AND t.status = '{status}'" if status and status != "All" else "",
#                 priority_condition=f"AND t.priority = '{priority}'" if priority and priority != "All" else ""
#             ), {"user": user}, as_dict=True)
            
#             # Clean HTML from descriptions
#             for task in task_list:
#                 if task.get('description'):
#                     task['description'] = clean_html(task['description'])
            
#             tasks = task_list
#         else:
#             # Admin: Get all tasks
#             tasks = frappe.get_list(
#                 "Task",
#                 filters=filters,
#                 fields=["name", "subject", "status", "priority", "exp_start_date", 
#                         "exp_end_date", "description", "owner", "project"],
#                 order_by="exp_end_date asc",
#                 limit_page_length=100
#             )
            
#             # Clean HTML from descriptions
#             for task in tasks:
#                 if task.get('description'):
#                     task['description'] = clean_html(task['description'])

#         return {
#             "status": "success", 
#             "message": f"Found {len(tasks)} tasks assigned to you",
#             "data": tasks
#         }

#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get Tasks API Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def get_users_for_assignment():
#     """
#     Get list of users that can be assigned to tasks.
#     Returns users with their email and full name.
#     """
#     try:
#         if frappe.session.user == "Guest":
#             return {"status": "error", "message": _("Authentication required")}
        
#         # Get all enabled users (excluding Guest and Administrator if needed)
#         users = frappe.get_all(
#             "User",
#             filters={"enabled": 1, "name": ["not in", ["Guest"]]},
#             fields=["name", "full_name", "email"],
#             order_by="full_name asc",
#             limit_page_length=200
#         )
        
#         return {
#             "status": "success",
#             "data": users,
#             "message": f"Found {len(users)} users"
#         }
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get Users for Assignment Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def assign_task(task_id, assign_to_users, complete_by=None, priority=None, comment=None):
#     """
#     Assign a task to one or more users.
#     This creates ToDo records for each assigned user.
    
#     Parameters:
#     - task_id: Task ID to assign
#     - assign_to_users: JSON string or list of user emails
#     - complete_by: Optional due date for the assignment
#     - priority: Optional priority (Low, Medium, High)
#     - comment: Optional comment/description
#     """
#     try:
#         if frappe.session.user == "Guest":
#             return {"status": "error", "message": _("Authentication required")}
        
#         # Validate task exists
#         if not frappe.db.exists("Task", task_id):
#             return {"status": "error", "message": "Task not found"}
        
#         # Parse assign_to_users if it's a JSON string
#         import json
#         if isinstance(assign_to_users, str):
#             try:
#                 assign_to_users = json.loads(assign_to_users)
#             except:
#                 assign_to_users = [assign_to_users]
        
#         # Ensure it's a list
#         if not isinstance(assign_to_users, list):
#             assign_to_users = [assign_to_users]
        
#         # Use Frappe's assign_to module to handle assignments
#         from frappe.desk.form.assign_to import add as add_assignment
        
#         assigned_users = []
#         for user_email in assign_to_users:
#             try:
#                 # Add assignment
#                 add_assignment({
#                     "assign_to": [user_email],
#                     "doctype": "Task",
#                     "name": task_id,
#                     "description": comment or f"Assigned via Mobile App by {frappe.session.user}",
#                     "priority": priority or "Medium",
#                     "date": complete_by
#                 })
#                 assigned_users.append(user_email)
#             except Exception as assign_error:
#                 frappe.log_error(f"Error assigning to {user_email}: {str(assign_error)}")
#                 continue
        
#         return {
#             "status": "success",
#             "message": f"Task assigned to {len(assigned_users)} user(s)",
#             "assigned_to": assigned_users
#         }
        
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Assign Task Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def get_task_assignments(task_id):
#     """
#     Get all users assigned to a specific task.
#     Returns list of assigned users with their assignment details.
#     """
#     try:
#         if frappe.session.user == "Guest":
#             return {"status": "error", "message": _("Authentication required")}
        
#         # Get ToDo records for this task
#         assignments = frappe.get_all(
#             "ToDo",
#             filters={
#                 "reference_type": "Task",
#                 "reference_name": task_id,
#                 "status": ["!=", "Cancelled"]
#             },
#             fields=["name", "allocated_to", "description", "priority", "date", "status"],
#             order_by="creation desc"
#         )
        
#         return {
#             "status": "success",
#             "data": assignments,
#             "count": len(assignments)
#         }
        
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Get Task Assignments Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def unassign_task(task_id, user_email):
#     """
#     Remove a user assignment from a task.
#     """
#     try:
#         if frappe.session.user == "Guest":
#             return {"status": "error", "message": _("Authentication required")}
        
#         # Find and cancel the ToDo record
#         from frappe.desk.form.assign_to import remove as remove_assignment
        
#         remove_assignment("Task", task_id, user_email)
        
#         return {
#             "status": "success",
#             "message": f"Unassigned {user_email} from task"
#         }
        
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Unassign Task Error")
#         return {"status": "error", "message": str(e)}

# @frappe.whitelist()
# def get_dashboard_stats():
#     """
#     Returns counts for Dashboard: Leads, Tasks, Projects.
#     All counts are user-specific (assigned to the logged-in user).
#     """
#     try:
#         user = frappe.session.user
#         if user == "Guest":
#             return {"status": "error", "message": "Authentication required"}

#         roles = frappe.get_roles(user)
#         is_admin = any(role in ["System Manager", "Administrator"] for role in roles)

#         # 1. Leads Count (My Leads, Open)
#         lead_filters = {"status": ["not in", ["Converted", "Lost", "Do Not Contact"]]}
#         if user != "Administrator":
#              lead_filters["lead_owner"] = user
        
#         leads_count = frappe.db.count("Lead", filters=lead_filters)

#         # 2. Tasks Count (My Tasks, Open/Active)
#         if is_admin:
#             tasks_count = frappe.db.count("Task", filters={
#                 "status": ["in", ["Open", "Working", "Pending Review", "Overdue"]]
#             })
#         else:
#             # Count tasks assigned to user
#             tasks_count = frappe.db.sql("""
#                 SELECT COUNT(DISTINCT t.name)
#                 FROM `tabTask` t
#                 LEFT JOIN `tabToDo` td ON td.reference_type = 'Task' 
#                     AND td.reference_name = t.name 
#                     AND td.allocated_to = %(user)s
#                 WHERE (t.owner = %(user)s OR td.allocated_to = %(user)s)
#                   AND t.status IN ('Open', 'Working', 'Pending Review', 'Overdue')
#             """, {"user": user})[0][0]

#         # 3. Projects Count (My Projects, Active)
#         if is_admin:
#             project_count = frappe.db.count("Project", filters={"status": "Open"})
#         else:
#             # Count projects where user is involved
#             project_count = frappe.db.sql("""
#                 SELECT COUNT(DISTINCT p.name)
#                 FROM `tabProject` p
#                 LEFT JOIN `tabProject User` pu ON pu.parent = p.name AND pu.user = %(user)s
#                 WHERE (p.owner = %(user)s OR pu.user = %(user)s)
#                   AND p.status = 'Open'
#             """, {"user": user})[0][0]

#         return {
#             "status": "success",
#             "data": {
#                 "leads_count": leads_count,
#                 "tasks_count": tasks_count,
#                 "projects_count": project_count
#             }
#         }
#     except Exception as e:
#         frappe.log_error(frappe.get_traceback(), "Dashboard Stats Error")
#         return {"status": "error", "message": str(e)}



import frappe
from frappe import _
from frappe.utils import nowdate
import re
import json
import requests
from html import unescape

def clean_html(text):
    """Remove HTML tags and clean text for mobile display"""
    if not text:
        return ""
    # Remove HTML tags
    text = re.sub(r'<[^>]+>', '', text)
    # Unescape HTML entities
    text = unescape(text)
    # Remove extra whitespace
    text = ' '.join(text.split())
    return text.strip()


@frappe.whitelist(allow_guest=True)
def login(usr, pwd):
    try:
        login_manager = frappe.auth.LoginManager()
        login_manager.authenticate(usr, pwd)
        login_manager.post_login()

        # Fetch user doc
        user_doc = frappe.get_doc("User", frappe.session.user)

        # Get all roles for the logged in user (excluding "All")
        roles = frappe.get_roles(frappe.session.user)
        roles = [r for r in roles if r != "All"]

        # Fetch Linked Employee
        employee_details = frappe.db.get_value(
            "Employee", 
            {"user_id": frappe.session.user}, 
            ["name", "employee_name", "image", "designation", "department"],
            as_dict=True
        )

        frappe.response["message"] = "Logged In"
        frappe.response["first_name"] = user_doc.first_name
        frappe.response["sid"] = frappe.session.sid
        frappe.response["roles"] = roles
        
        # Add Employee Info to Response
        if employee_details:
             frappe.response["employee_info"] = employee_details
        else:
             frappe.response["employee_info"] = None

        # Chart visibility logic (Example logic based on your request)
        allowed_chart_roles = ["Kmcc Constituency Admin", "Kmcc District Admin", "Administrator", "Admin"]
        frappe.response["show_chart"] = any(role in allowed_chart_roles for role in roles)

    except frappe.AuthenticationError:
        frappe.clear_messages()
        frappe.response["message"] = "Invalid username or password"
        frappe.response["error"] = True

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Mobile Login Error")
        frappe.response["message"] = "An error occurred during login"
        frappe.response["error"] = str(e)

@frappe.whitelist()
def get_logged_in_user_info():
    try:
        if frappe.session.user == "Guest":
            return {"status": "error", "message": "User not logged in"}

        user = frappe.session.user

        # Get user full name
        full_name = frappe.db.get_value("User", user, "full_name")

        # Check linked employee
        employee_id = frappe.db.get_value("Employee", {"user_id": user}, "name")

        return {
            "status": "success",
            "user": {
                "user_id": user,
                "full_name": full_name,
                "employee_id": employee_id
            }
        }

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Logged-in User Info API Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def get_project_names(search_text=None, status=None, from_date=None, to_date=None):
    """
    Fetch projects where the logged-in user is involved, with optional filters.
    Returns projects where user is the owner, project manager, or assigned as a team member.
    
    Filters: search_text, status, from_date, to_date
    """
    try:
        user = frappe.session.user
        if user == "Guest":
            return {"status": "error", "message": _("Authentication required")}

        roles = frappe.get_roles(user)
        is_admin = any(role in ["System Manager", "Administrator", "Projects Manager"] for role in roles)

        if is_admin:
            # Admin: Get all active projects with filters
            filters = {"status": ["!=", "Cancelled"]}
            
            # Apply search filter
            if search_text:
                filters["project_name"] = ["like", f"%{search_text}%"]
            
            # Apply status filter
            if status and status != "All":
                filters["status"] = status
            
            # Apply date filters
            if from_date:
                if "creation" not in filters:
                    filters["creation"] = []
                filters["creation"].append([">=", from_date])
            if to_date:
                if "creation" not in filters:
                    filters["creation"] = []
                filters["creation"].append(["<=", to_date])
            
            projects = frappe.get_all(
                "Project",
                filters=filters,
                fields=["name", "project_name", "status", "project_type", "is_active", 
                        "percent_complete_method", "expected_start_date", "expected_end_date", 
                        "priority", "percent_complete"],
                order_by="creation desc"
            )
        else:
            # Get projects where user is involved (owner, or team member) with filters
            # Using SQL to check Project Users child table
            project_list = frappe.db.sql("""
                SELECT DISTINCT p.name, p.project_name, p.status, p.project_type, 
                       p.is_active, p.percent_complete_method, p.expected_start_date, 
                       p.expected_end_date, p.priority, p.percent_complete
                FROM `tabProject` p
                LEFT JOIN `tabProject User` pu ON pu.parent = p.name AND pu.user = %(user)s
                WHERE (p.owner = %(user)s OR pu.user = %(user)s)
                  AND p.status != 'Cancelled'
                  {search_condition}
                  {status_condition}
                  {from_date_condition}
                  {to_date_condition}
                ORDER BY p.creation DESC
                LIMIT 100
            """.format(
                search_condition=f"AND p.project_name LIKE '%{search_text}%'" if search_text else "",
                status_condition=f"AND p.status = '{status}'" if status and status != "All" else "",
                from_date_condition=f"AND p.creation >= '{from_date}'" if from_date else "",
                to_date_condition=f"AND p.creation <= '{to_date}'" if to_date else ""
            ), {"user": user}, as_dict=True)
            
            projects = project_list

        return {
            "status": "success",
            "message": f"Found {len(projects)} projects",
            "projects": projects
        }
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Project Names Error")
        return {
            "status": "error",
            "message": str(e)
        }

@frappe.whitelist()
def get_leads(search_text=None, status=None, from_date=None, to_date=None):
    try:
        if frappe.session.user == "Guest":
            return {"status": "error", "message": _("Authentication required")}

        user_email = frappe.session.user
        
        # Build filter conditions
        conditions = []
        
        # Search Filter (Lead Name, Company, Email)
        if search_text:
            conditions.append(f"(l.lead_name LIKE '%{search_text}%' OR l.company_name LIKE '%{search_text}%' OR l.email_id LIKE '%{search_text}%')")

        # Status Filter
        if status and status != "All":
            conditions.append(f"l.status = '{status}'")

        # Date Filter
        if from_date:
            conditions.append(f"l.creation >= '{from_date}'")
        if to_date:
            conditions.append(f"l.creation <= '{to_date}'")
            
        where_clause = " AND ".join(conditions)
        if where_clause:
            where_clause = " AND " + where_clause

        # User permission filter: Owner, Email match, OR Assigned via ToDo
        permission_condition = ""
        if user_email != "Administrator":
             permission_condition = """
                AND (
                    l.lead_owner = %(user)s 
                    OR l.email_id = %(user)s 
                    OR t.name IS NOT NULL
                )
             """

        # SQL Query to fetch Lead Names
        query = f"""
            SELECT DISTINCT l.name
            FROM `tabLead` l
            LEFT JOIN `tabToDo` t ON t.reference_name = l.name AND t.reference_type = 'Lead' AND t.allocated_to = %(user)s
            WHERE l.name IS NOT NULL
            {permission_condition}
            {where_clause}
            ORDER BY l.creation DESC
            LIMIT 100
        """

        lead_names = frappe.db.sql(query, {"user": user_email}, as_dict=True)

        leads = []
        for lead_entry in lead_names:
            lead_doc = frappe.get_doc("Lead", lead_entry.name)

            leads.append({
                "name": lead_doc.name,
                "lead_name": lead_doc.lead_name,
                "lead_owner": lead_doc.lead_owner,
                "status": lead_doc.status,
                "source": lead_doc.source,
                "type": lead_doc.type,
                "request_type": lead_doc.request_type,
                "gender": lead_doc.gender,
                "phone": lead_doc.phone,
                "mobile_no": lead_doc.mobile_no,
                "company_name": lead_doc.company_name,
                "annual_revenue": lead_doc.annual_revenue,
                "industry": lead_doc.industry,
                "market_segment": lead_doc.market_segment,
                "territory": lead_doc.territory,
                "city": lead_doc.city,
                "country": lead_doc.country,
                "open_activities_html": lead_doc.get("open_activities_html"),
                "all_activities_html": lead_doc.get("all_activities_html"),
                "notes": [
                    {
                        "note": clean_html(n.note) if n.note else "",
                        "added_by": n.added_by,
                        "added_on": n.added_on
                    }
                    for n in lead_doc.notes
                ]
            })

        return {
            "status": "success",
            "message": "Leads fetched successfully with activities",
            "leads": leads
        }
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Leads Error")
        return {
            "status": "error",
            "message": str(e)
        }

@frappe.whitelist()
def assign_lead(lead_id, assign_to_users, priority="Medium", complete_by=None, comment=None):
    try:
        from frappe.desk.form.assign_to import add as add_assignment
        
        if isinstance(assign_to_users, str):
            import json
            try:
                assign_to_users = json.loads(assign_to_users)
            except:
                assign_to_users = [assign_to_users]
                
        if not assign_to_users:
             return {"status": "error", "message": "No users selected for assignment"}
             
        for user in assign_to_users:
            args = {
                "assign_to": [user],
                "doctype": "Lead",
                "name": lead_id,
                "description": comment or f"Assigned by {frappe.session.user}",
                "priority": priority
            }
            if complete_by:
                args['date'] = complete_by
                
            add_assignment(args)
            
            # Send Notification
            send_fcm_notification(
                user, 
                "New Lead Assigned", 
                f"You have been assigned a new lead: {lead_id}",
                {"doctype": "Lead", "name": lead_id}
            )
            
        return {"status": "success", "message": "Lead assigned successfully"}
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Assign Lead Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def get_lead_assignments(lead_id):
    """
    Get all users assigned to a specific lead.
    Returns list of assigned users with their assignment details.
    """
    try:
        if frappe.session.user == "Guest":
            return {"status": "error", "message": _("Authentication required")}
        
        # Get ToDo records for this lead
        assignments = frappe.get_all(
            "ToDo",
            filters={
                "reference_type": "Lead",
                "reference_name": lead_id,
                "status": ["!=", "Cancelled"]
            },
            fields=["name", "allocated_to", "description", "priority", "date", "status"],
            order_by="creation desc"
        )
        
        return {
            "status": "success",
            "data": assignments,
            "count": len(assignments)
        }
        
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Lead Assignments Error")
        return {"status": "error", "message": str(e)}


@frappe.whitelist()
def create_lead(lead_name, mobile_no, email_id=None, company_name=None):
    """
    Creates a new Lead in ERPNext.
    """
    try:
        new_lead = frappe.new_doc("Lead")
        new_lead.first_name = lead_name
        new_lead.mobile_no = mobile_no
        new_lead.email_id = email_id
        new_lead.company_name = company_name
        new_lead.lead_owner = frappe.session.user
        new_lead.status = "Lead"
        new_lead.save()
        return {"status": "success", "message": "Lead created successfully", "data": new_lead.name}
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Create Lead Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def get_lead_connections(lead_name):
    try:
        if not frappe.db.exists("Lead", lead_name):
            return {"status": "error", "message": "Lead does not exist."}

        # Get linked Opportunities
        opportunities = frappe.get_all("Opportunity", filters={"party_name": lead_name, "opportunity_from": "Lead"}, fields=["name"])

        # Get linked Quotations
        quotations = frappe.get_all("Quotation", filters={"party_name": lead_name}, fields=["name"])

        # Get linked Prospects
        prospects = frappe.get_all("Prospect", filters={"lead": lead_name}, fields=["name"])

        return {
            "status": "success",
            "opportunities": opportunities,
            "quotations": quotations,
            "prospects": prospects
        }

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Lead Connections Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def get_sales_person():
    try:
        current_user = frappe.session.user

        if current_user == "Guest":
            return {"status": "error", "message": _("Login required")}

        roles = frappe.get_roles(current_user)

        # Admin / Manager shows all sales persons
        if "Sales Manager" in roles or "System Manager" in roles:
            sales_persons = frappe.get_all(
                "Sales Person",
                fields=["name", "sales_person_name"]
            )
            return {"status": "success", "data": sales_persons}

        # For Sales Person role -> show only linked one
        else:
            # Find Sales Person linked to user
            sales_person_doc = frappe.db.get_value(
                "Sales Person",
                {"custom_user": current_user},
                ["name", "sales_person_name"],
                as_dict=True
            )

            if sales_person_doc:
                return {"status": "success", "data": [sales_person_doc]}
            else:
                return {"status": "error", "message": _("No Sales Person linked to user")}

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "get_sales_person API Error")
        return {"status": "error", "message": str(e)}


@frappe.whitelist()
def get_employee_list_with_user():
    """
    Fetches a list of all Employees who are linked to a system User.
    Returns their Employee ID ('name') and Full Name ('employee_name').
    """
    try:
        if frappe.session.user == "Guest":
            return {
                "status": "error",
                "message": _("Authentication required.")
            }

        employees = frappe.get_all(
            "Employee",
            filters={"user_id": ["!=", ""]},
            fields=["name", "employee_name"],
            order_by="employee_name asc"
        )

        return {"status": "success", "data": employees}

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Employee List with User API Error")
        return {
            "status": "error",
            "message": str(e)
        }

# ----------------- TASKS MODULE (Added based on requirements) -----------------

@frappe.whitelist()
def get_my_tasks():
    """
    Fetch tasks assigned to the current user or created by them.
    Using standard 'Task' doctype.
    """
    try:
        if frappe.session.user == "Guest":
            return {"status": "error", "message": _("Authentication required")}
            
        tasks = frappe.get_all(
            "Task",
            filters=[
                ["status", "!=", "Cancelled"],
                ["_assign", "like", f"%{frappe.session.user}%"]
            ],
            fields=["name", "subject", "status", "priority", "exp_end_date", "description", "project"],
            order_by="exp_end_date asc"
        )
        
        # Clean HTML from descriptions
        for task in tasks:
            if task.get('description'):
                task['description'] = clean_html(task['description'])
        
        return {"status": "success", "data": tasks}
        
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get My Tasks Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def create_task(subject, description, date, priority="Medium", assign_to=None):
    try:
        new_task = frappe.new_doc("Task")
        new_task.subject = subject
        new_task.description = description
        new_task.exp_end_date = date
        new_task.priority = priority
        new_task.save()
        
        # Handle assignments if provided
        assigned_to_users = []
        if assign_to:
            import json
            # Parse if string/JSON
            if isinstance(assign_to, str):
                try:
                    assign_to = json.loads(assign_to)
                except:
                    assign_to = [assign_to]
            
            # Ensure list
            if not isinstance(assign_to, list):
                assign_to = [assign_to]
                
            # Use assignment API logic
            from frappe.desk.form.assign_to import add as add_assignment
            
            for user in assign_to:
                try:
                    add_assignment({
                        "assign_to": [user],
                        "doctype": "Task",
                        "name": new_task.name,
                        "description": f"Assigned upon creation by {frappe.session.user}",
                        "priority": priority,
                        "date": date
                    })
                    assigned_to_users.append(user)
                except Exception as e:
                    frappe.log_error(f"Failed to assign to {user}: {str(e)}")

        # If no explicit assignment, can we auto-assign to creator? 
        # Requirement says "assign to users", so only if requested.
        
        return {
            "status": "success", 
            "message": "Task created successfully", 
            "data": new_task.name,
            "assigned_to": assigned_to_users
        }
        
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Create Task Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def update_task_status(task_id, status):
    """
    Update status of a task (e.g., Open, Completed)
    """
    try:
        task = frappe.get_doc("Task", task_id)
        task.status = status
        task.save()
        return {"status": "success", "message": "Task status updated"}
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Update Task Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def get_tasks(search_text=None, status=None, priority=None):
    """
    Fetch tasks assigned to the logged-in user.
    Returns tasks where user is the owner OR assigned to the task.
    This acts as a TODO list for the user.
    """
    try:
        user = frappe.session.user
        if user == "Guest":
            return {"status": "error", "message": _("Authentication required")}

        roles = frappe.get_roles(user)
        is_admin = any(role in ["System Manager", "Administrator"] for role in roles)

        # Build base filters
        filters = {"status": ["!=", "Cancelled"]}

        # Search Filter
        if search_text:
            filters["subject"] = ["like", f"%{search_text}%"]
        
        # Status Filter
        if status and status != "All":
            filters["status"] = status

        # Priority Filter
        if priority and priority != "All":
            filters["priority"] = priority

        # For non-admin users, filter by assigned tasks using SQL
        if not is_admin:
            # Get tasks where user is in _assign field (JSON field storing assigned users)
            # OR where user is the owner
            task_list = frappe.db.sql("""
                SELECT DISTINCT t.name, t.subject, t.status, t.priority, 
                       t.exp_start_date, t.exp_end_date, t.description, 
                       t.owner, t.project
                FROM `tabTask` t
                LEFT JOIN `tabToDo` td ON td.reference_type = 'Task' 
                    AND td.reference_name = t.name 
                    AND td.allocated_to = %(user)s
                WHERE (t.owner = %(user)s OR td.allocated_to = %(user)s)
                  AND t.status != 'Cancelled'
                  {search_condition}
                  {status_condition}
                  {priority_condition}
                ORDER BY t.exp_end_date ASC
                LIMIT 100
            """.format(
                search_condition=f"AND t.subject LIKE '%{search_text}%'" if search_text else "",
                status_condition=f"AND t.status = '{status}'" if status and status != "All" else "",
                priority_condition=f"AND t.priority = '{priority}'" if priority and priority != "All" else ""
            ), {"user": user}, as_dict=True)
            
            # Clean HTML from descriptions
            for task in task_list:
                if task.get('description'):
                    task['description'] = clean_html(task['description'])
            
            tasks = task_list
        else:
            # Admin: Get all tasks
            tasks = frappe.get_list(
                "Task",
                filters=filters,
                fields=["name", "subject", "status", "priority", "exp_start_date", 
                        "exp_end_date", "description", "owner", "project"],
                order_by="exp_end_date asc",
                limit_page_length=100
            )
            
            # Clean HTML from descriptions
            for task in tasks:
                if task.get('description'):
                    task['description'] = clean_html(task['description'])

        return {
            "status": "success", 
            "message": f"Found {len(tasks)} tasks assigned to you",
            "data": tasks
        }

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Tasks API Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def get_users_for_assignment():
    """
    Get list of users that can be assigned to tasks.
    Returns users with their email and full name.
    """
    try:
        if frappe.session.user == "Guest":
            return {"status": "error", "message": _("Authentication required")}
        
        # Get all enabled users (excluding Guest and Administrator if needed)
        users = frappe.get_all(
            "User",
            filters={"enabled": 1, "name": ["not in", ["Guest"]]},
            fields=["name", "full_name", "email"],
            order_by="full_name asc",
            limit_page_length=200
        )
        
        return {
            "status": "success",
            "data": users,
            "message": f"Found {len(users)} users"
        }
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Users for Assignment Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def assign_task(task_id, assign_to_users, complete_by=None, priority=None, comment=None):
    """
    Assign a task to one or more users.
    This creates ToDo records for each assigned user.
    
    Parameters:
    - task_id: Task ID to assign
    - assign_to_users: JSON string or list of user emails
    - complete_by: Optional due date for the assignment
    - priority: Optional priority (Low, Medium, High)
    - comment: Optional comment/description
    """
    try:
        if frappe.session.user == "Guest":
            return {"status": "error", "message": _("Authentication required")}
        
        # Validate task exists
        if not frappe.db.exists("Task", task_id):
            return {"status": "error", "message": "Task not found"}
        
        # Parse assign_to_users if it's a JSON string
        import json
        if isinstance(assign_to_users, str):
            try:
                assign_to_users = json.loads(assign_to_users)
            except:
                assign_to_users = [assign_to_users]
        
        # Ensure it's a list
        if not isinstance(assign_to_users, list):
            assign_to_users = [assign_to_users]
        
        # Use Frappe's assign_to module to handle assignments
        from frappe.desk.form.assign_to import add as add_assignment
        
        assigned_users = []
        for user_email in assign_to_users:
            try:
                # Add assignment
                add_assignment({
                    "assign_to": [user_email],
                    "doctype": "Task",
                    "name": task_id,
                    "description": comment or f"Assigned via Mobile App by {frappe.session.user}",
                    "priority": priority or "Medium",
                    "date": complete_by
                })
                assigned_users.append(user_email)
                
                # Send Notification
                send_fcm_notification(
                    user_email, 
                    "New Task Assigned", 
                    f"You have been assigned a task: {task_id}",
                    {"doctype": "Task", "name": task_id}
                )
            except Exception as assign_error:
                frappe.log_error(f"Error assigning to {user_email}: {str(assign_error)}")
                continue
        
        return {
            "status": "success",
            "message": f"Task assigned to {len(assigned_users)} user(s)",
            "assigned_to": assigned_users
        }
        
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Assign Task Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def get_task_assignments(task_id):
    """
    Get all users assigned to a specific task.
    Returns list of assigned users with their assignment details.
    """
    try:
        if frappe.session.user == "Guest":
            return {"status": "error", "message": _("Authentication required")}
        
        # Get ToDo records for this task
        assignments = frappe.get_all(
            "ToDo",
            filters={
                "reference_type": "Task",
                "reference_name": task_id,
                "status": ["!=", "Cancelled"]
            },
            fields=["name", "allocated_to", "description", "priority", "date", "status"],
            order_by="creation desc"
        )
        
        return {
            "status": "success",
            "data": assignments,
            "count": len(assignments)
        }
        
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Get Task Assignments Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def unassign_task(task_id, user_email):
    """
    Remove a user assignment from a task.
    """
    try:
        if frappe.session.user == "Guest":
            return {"status": "error", "message": _("Authentication required")}
        
        # Find and cancel the ToDo record
        from frappe.desk.form.assign_to import remove as remove_assignment
        
        remove_assignment("Task", task_id, user_email)
        
        return {"status": "success", "message": f"Unassigned {user_email} from task"}
        
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Unassign Task Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def update_device_token(device_token):
    """
    Update or register FCM device token for the logged-in user.
    Requires 'User Device Token' Doctype to exist.
    """
    try:
        user = frappe.session.user
        if user == "Guest":
            return {"status": "error", "message": _("Authentication required")}

        if not device_token:
             return {"status": "error", "message": "Device token is required"}

        # Check if record exists for this user and token
        existing = frappe.db.get_value("User Device Token", 
                                     {"user": user, "device_token": device_token}, 
                                     "name")
        
        if not existing:
            # Create new record
            doc = frappe.new_doc("User Device Token")
            doc.user = user
            doc.device_token = device_token
            
            # Fetch Employee ID
            employee = frappe.db.get_value("Employee", {"user_id": user}, "name")
            if employee:
                doc.employee = employee
                
            doc.insert(ignore_permissions=True)
            frappe.db.commit()
            return {"status": "success", "message": "Token registered successfully"}
        else:
            return {"status": "success", "message": "Token already registered"}

    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Update Device Token Error")
        # If Doctype doesn't exist, return more helpful error
        if "Table 'tabUser Device Token' doesn't exist" in str(e):
             return {"status": "error", "message": "DocType 'User Device Token' not found in ERPNext."}
        return {"status": "error", "message": str(e)}

def send_fcm_notification(user_id, title, body, data=None):
    """
    Helper function to send FCM notification using Legacy API.
    server_key should be in site_config.json as 'fcm_server_key'
    """
    try:
        # Get all tokens for this user
        tokens = frappe.get_all("User Device Token", 
                             filters={"user": user_id}, 
                             fields=["device_token"])
        
        if not tokens:
            return
            
        registration_ids = [t['device_token'] for t in tokens]
        
        # Get server key from site config
        server_key = frappe.conf.get("fcm_server_key")
        
        if not server_key:
            frappe.log_error("FCM Server Key (fcm_server_key) not found in site_config.json", "FCM Skip")
            return

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"key={server_key}"
        }
        
        payload = {
            "registration_ids": registration_ids,
            "notification": {
                "title": title,
                "body": body,
                "sound": "default"
            },
            "data": data or {}
        }
        
        requests.post("https://fcm.googleapis.com/fcm/send", 
                     headers=headers, 
                     data=json.dumps(payload), 
                     timeout=10)
        
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Send FCM Notification Error")

@frappe.whitelist()
def get_dashboard_stats():
    """
    Returns counts for Dashboard: Leads, Tasks, Projects.
    All counts are user-specific (assigned to the logged-in user).
    """
    try:
        user = frappe.session.user
        if user == "Guest":
            return {"status": "error", "message": "Authentication required"}

        roles = frappe.get_roles(user)
        is_admin = any(role in ["System Manager", "Administrator"] for role in roles)

        # 1. Leads Count (My Leads, Open)
        lead_filters = {"status": ["not in", ["Converted", "Lost", "Do Not Contact"]]}
        if user != "Administrator":
             lead_filters["lead_owner"] = user
        
        leads_count = frappe.db.count("Lead", filters=lead_filters)

        # 2. Tasks Count (My Tasks, Open/Active)
        if is_admin:
            tasks_count = frappe.db.count("Task", filters={
                "status": ["in", ["Open", "Working", "Pending Review", "Overdue"]]
            })
        else:
            # Count tasks assigned to user
            tasks_count = frappe.db.sql("""
                SELECT COUNT(DISTINCT t.name)
                FROM `tabTask` t
                LEFT JOIN `tabToDo` td ON td.reference_type = 'Task' 
                    AND td.reference_name = t.name 
                    AND td.allocated_to = %(user)s
                WHERE (t.owner = %(user)s OR td.allocated_to = %(user)s)
                  AND t.status IN ('Open', 'Working', 'Pending Review', 'Overdue')
            """, {"user": user})[0][0]

        # 3. Projects Count (My Projects, Active)
        if is_admin:
            project_count = frappe.db.count("Project", filters={"status": "Open"})
        else:
            # Count projects where user is involved
            project_count = frappe.db.sql("""
                SELECT COUNT(DISTINCT p.name)
                FROM `tabProject` p
                LEFT JOIN `tabProject User` pu ON pu.parent = p.name AND pu.user = %(user)s
                WHERE (p.owner = %(user)s OR pu.user = %(user)s)
                  AND p.status = 'Open'
            """, {"user": user})[0][0]

        return {
            "status": "success",
            "data": {
                "leads_count": leads_count,
                "tasks_count": tasks_count,
                "projects_count": project_count
            }
        }
    except Exception as e:
        frappe.log_error(frappe.get_traceback(), "Dashboard Stats Error")
        return {"status": "error", "message": str(e)}

@frappe.whitelist()
def update_device_token(token, employee=None):
    """
    Registers or updates the FCM device token for the current user.
    """
    user = frappe.session.user
    if user == "Guest":
        return {"status": "error", "message": "Login required"}

    if not token:
        return {"status": "error", "message": "Token is required"}

    # Check if this token already exists for another user and remove it (optional but good practice)
    # frappe.db.delete("User Device Token", {"device_token": token, "user": ["!=", user]})

    if frappe.db.exists("User Device Token", {"user": user, "device_token": token}):
        return {"status": "success", "message": "Token already registered"}

    # Create new entry
    doc = frappe.get_doc({
        "doctype": "User Device Token",
        "user": user,
        "device_token": token,
        "employee": employee or frappe.db.get_value("Employee", {"user_id": user}, "name")
    })
    doc.insert(ignore_permissions=True)
    frappe.db.commit()

    return {"status": "success", "message": "Device token registered successfully"}
