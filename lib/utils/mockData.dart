import 'package:eschool/utils/api.dart';

class MockData {
  static Map<String, dynamic>? getMockResponse(
      String url, dynamic body, String method) {
    print("🌐 MOCK INTERCEPTOR: $method $url");

    // ==========================================
    // AUTHENTICATION
    // ==========================================
    if (url == Api.parentLogin) {
      return {
        "error": false,
        "message": "Login successful",
        "data": {
          "id": 1,
          "first_name": "Budi",
          "last_name": "Santoso",
          "email": "budi.santoso@example.com",
          "mobile": "081234567890",
          "gender": "Male",
          "current_address": "Jl. Mawar No 10, Jakarta",
          "permanent_address": "Jl. Mawar No 10, Jakarta",
          "status": 1,
          "image": "",
          "children": [
            {
              "id": 101,
              "token": "mock_student_jwt_token",
              "school_code": "SCH001",
              "first_name": "Mawar",
              "last_name": "Melati",
              "dob": "2010-05-15",
              "admission_no": "ADM-2023-001",
              "roll_number": 12,
              "class_section": {
                "id": 1,
                "class": {"id": 1, "name": "Class 8"},
                "section": {"id": 1, "name": "A"}
              },
              "user": {
                "id": 101,
                "first_name": "Mawar",
                "last_name": "Melati",
                "school": {"code": "SCH001", "name": "E-School Mock Academy"}
              },
              "school": {"code": "SCH001", "name": "E-School Mock Academy"}
            }
          ]
        }
      };
    }

    if (url == Api.studentLogin) {
      return {
        "error": false,
        "message": "Login successful",
        "token": "mock_student_jwt_token",
        "data": {
          "id": 101,
          "first_name": "Mawar",
          "last_name": "Melati",
          "email": "mawar@student.com",
          "mobile": "081299998888",
          "gender": "Female",
          "current_address": "Jl. Melati No 5",
          "permanent_address": "Jl. Melati No 5",
          "status": 1,
          "image": "",
          "dob": "2010-05-15",
          "admission_no": "ADM-2023-001",
          "roll_number": 12,
          "class_section": {
            "id": 1,
            "class": {"id": 1, "name": "Class 8"},
            "section": {"id": 1, "name": "A"}
          },
          "school": {"code": "SCH001", "name": "E-School Mock Academy"}
        }
      };
    }

    // ==========================================
    // PARENT DASHBOARD & CHILDREN LIST
    // ==========================================
    // Note: get-child-profile-data might be called with params, but since we are mocking, we match the base URL.
    if (url.contains(Api.childProfileDetails) ||
        url.contains("parent/get-child-profile-data")) {
      return {
        "error": false,
        "message": "Success",
        "data": [
          {
            "id": 101,
            "first_name": "Mawar",
            "last_name": "Melati",
            "dob": "2010-05-15",
            "admission_no": "ADM-2023-001",
            "roll_number": 12,
            "guardian_id": 1,
            "class_section_id": 1,
            "shift_id": 1,
            "user": {
              "id": 101,
              "first_name": "Mawar",
              "last_name": "Melati",
              "image": ""
            },
            "class_section": {
              "id": 1,
              "class": {"id": 1, "name": "Class 8"},
              "section": {"id": 1, "name": "A"}
            },
            "school": {"name": "SMP Negeri 1"}
          }
        ]
      };
    }

    // System Settings (Usually required on boot)
    if (url.contains("settings") || url == Api.settings) {
      return {
        "error": false,
        "message": "Settings fetched",
        "data": {
          "currency_symbol": "Rp",
          "currency_code": "IDR",
          "school_name": "E-School Mock",
          "session_year": {"id": 1, "name": "2025-2026"}
        }
      };
    }

    // ==========================================
    // DASHBOARD DATA (SUBJECTS, SLIDERS, ETC)
    // ==========================================

    // Subjects
    if (url.contains("student/subjects") || url.contains("parent/subjects")) {
      return {
        "error": false,
        "message": "Subjects fetched",
        "data": {
          "core_subject": [
            {
              "id": 1,
              "name": "Matematika",
              "code": "MATH",
              "bg_color": "#FF5733",
              "image": "",
              "type": "Practical",
              "pivot": {"class_id": 1}
            },
            {
              "id": 2,
              "name": "BHS Indonesia",
              "code": "IND",
              "bg_color": "#33FF57",
              "image": "",
              "type": "Theory",
              "pivot": {"class_id": 1}
            }
          ],
          "elective_subject": []
        }
      };
    }

    // Sliders
    if (url.contains("sliders")) {
      return {
        "error": false,
        "message": "Sliders fetched",
        "data": [
          {
            "id": 1,
            "image": "https://picsum.photos/600/300",
            "link": "",
            "school_id": 1,
            "created_at": "2025-10-01",
            "updated_at": "2025-10-01"
          }
        ]
      };
    }

    // Announcements
    if (url.contains("announcements")) {
      return {
        "error": false,
        "message": "Announcements fetched",
        "data": {
          "data": [
            {
              "id": 1,
              "title": "Welcome to E-School",
              "description": "Mock announcements are now working!",
              "created_at": "2025-10-01T10:00:00.000000Z",
              "creator": "System Admin",
              "file": []
            }
          ],
          "last_page": 1,
          "current_page": 1
        }
      };
    }

    // Attendance
    if (url.contains("attendance")) {
      return {
        "error": false,
        "message": "Attendance fetched",
        "data": {
          "attendance": [
            {
              "id": 1,
              "student_id": 101,
              "session_year_id": 1,
              "type": 1,
              "date": "2025-10-01",
              "remark": "On time"
            }
          ],
          "session_year": {"id": 1, "name": "2025-2026"}
        }
      };
    }

    // Timetable
    if (url.contains("timetable")) {
      return {
        "error": false,
        "message": "Timetable fetched",
        "data": [
          {
            "start_time": "08:00:00",
            "end_time": "09:30:00",
            "day": "1",
            "note": "Regular Class",
            "teacher_first_name": "Budi",
            "teacher_last_name": "Guru",
            "subject": {
              "id": 1,
              "name": "Matematika",
              "code": "MATH",
              "bg_color": "#FF5733",
              "type": "Practical"
            }
          }
        ]
      };
    }

    // ==========================================
    // EXAMS
    // ==========================================
    if (url.contains("get-exam-list")) {
      return {
        "error": false,
        "message": "Exams fetched",
        "data": {
          "data": [
            {
              "id": 1,
              "name": "Mid Term Exam",
              "description": "Semester 1 Mid Term",
              "publish": 1,
              "session_year": "2025-2026",
              "exam_starting_date": "2025-10-01",
              "exam_ending_date": "2025-10-10",
              "exam_status": "2" // completed
            }
          ]
        }
      };
    }

    // ==========================================
    // EXAM MARKS / RESULTS
    // ==========================================
    if (url.contains("exam-marks")) {
      return {
        "error": false,
        "message": "Results fetched",
        "data": [
          {
            "result": {
              "result_id": 1,
              "exam_id": 1,
              "exam_name": "Mid Term Exam",
              "description": "Semester 1 Mid Term",
              "exam_date": "2025-10-01",
              "session_year": "2025-2026",
              "total_marks": 100,
              "obtained_marks": 85,
              "percentage": 85.0,
              "grade": "A"
            },
            "exam_marks": [
              {
                "id": 1,
                "subject": {
                  "id": 1,
                  "name": "Matematika",
                  "code": "MATH",
                  "bg_color": "#FF5733",
                  "type": "Practical"
                },
                "total_marks": 100,
                "passing_marks": 60,
                "obtained_marks": 85,
                "teacher_review": "Good"
              }
            ]
          }
        ]
      };
    }

    // ==========================================
    // ASSIGNMENTS
    // ==========================================
    if (url.contains("assignments")) {
      return {
        "error": false,
        "message": "Assignments fetched",
        "data": {
          "data": [
            {
              "id": 1,
              "class_section_id": 1,
              "subject_id": 1,
              "name": "Math Homework 1",
              "instructions": "Solve equations 1-10",
              "due_date": "2025-11-01 23:59:59",
              "points": 100,
              "resubmission": 0,
              "extra_days_for_resubmission": 0,
              "session_year_id": 1,
              "class_subject": {
                "subject": {
                  "id": 1,
                  "name": "Matematika",
                  "code": "MATH",
                  "bg_color": "#FF5733",
                  "type": "Practical",
                  "pivot": {"class_id": 1}
                }
              },
              "created_at": "2025-10-01T10:00:00.000000Z",
              "school_id": 1,
              "max_file": 1,
              "filetypes": ["pdf", "jpg"]
            }
          ],
          "last_page": 1,
          "current_page": 1
        }
      };
    }

    // ==========================================
    // FEES
    // ==========================================
    if (url.contains("fees") && !url.contains("paid")) {
      return {
        "error": false,
        "message": "Fees fetched",
        "data": {
          "bills": [
            {
              "id": 1,
              "name": "Tuition Fee Semester 1",
              "due_date": "2025-08-01",
              "original_amount": 500000,
              "type": "compulsory",
              "total_amount": 500000,
              "paid_amount": 0,
              "remaining_amount": 500000,
              "status": "unpaid",
              "payment_history": []
            }
          ],
          "compulsory_fees": [],
          "optional_fees": [],
          "payment_methods": []
        }
      };
    }

    // ==========================================
    // HOLIDAYS
    // ==========================================
    if (url.contains("holidays")) {
      return {
        "error": false,
        "message": "Holidays fetched",
        "data": [
          {
            "id": 1,
            "title": "Semester Break",
            "description": "Holiday",
            "date": "2025-12-25"
          }
        ]
      };
    }

    // ==========================================
    // GALLERY
    // ==========================================
    if (url.contains("gallery")) {
      return {
        "error": false,
        "message": "Gallery fetched",
        "data": {"data": [], "last_page": 1, "current_page": 1}
      };
    }

    // ==========================================
    // TEACHERS (PARENT APP)
    // ==========================================
    if (url.contains("teachers")) {
      return {"error": false, "message": "Teachers fetched", "data": []};
    }

    // ==========================================
    // EXTRACURRICULAR
    // ==========================================
    if (url.contains("eskul") || url.contains("extracurricular")) {
      return {
        "error": false,
        "message": "Extracurriculars fetched",
        "data": []
      };
    }

    // ==========================================
    // LEAVES
    // ==========================================
    if (url.contains("leaves")) {
      return {
        "error": false,
        "message": "Leaves fetched",
        "data": {"data": [], "last_page": 1, "current_page": 1}
      };
    }

    // Fallback unmocked logger
    print("   ⚠️ UNMOCKED ENDPOINT: $url");
    return null; // Let the real API attempt to handle it, or throw an error if you want strict mocking
  }
}
