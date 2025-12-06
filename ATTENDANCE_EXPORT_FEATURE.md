# Attendance Export with Filters - Feature Summary

## Overview
Enhanced the attendance export functionality to allow admins to filter and export attendance records based on:
- **Subject Name** - Filter by specific subjects
- **Teacher Name** - Filter by specific teachers  
- **Date Range** - Filter by start and end dates

## Key Features

### 1. Flexible Filtering
- **Subject Filter**: Export attendance for a specific subject (e.g., only "Arabic Grammar")
- **Teacher Filter**: Export attendance for classes taught by a specific teacher
- **Date Range Filter**: Export attendance between specific dates
- **Combined Filters**: Use multiple filters together for precise data extraction
- **All Records**: Leave filters empty to export all attendance records

### 2. Smart File Naming
The exported Excel files are automatically named based on applied filters:
- `attendance_ArabicGrammar_20251206_115604.xlsx` (subject filter)
- `attendance_SheikhAhmed_20251206_115604.xlsx` (teacher filter)
- `attendance_from_20251201_to_20251206_115604.xlsx` (date range)
- `attendance_ArabicGrammar_SheikhAhmed_from_20251201_to_20251206_115604.xlsx` (combined)

### 3. Enhanced Excel Export
Each exported file includes:
- Date and Time of attendance
- Student Name and ID
- Subject Name
- Teacher Name
- Attendance Status (Present/Absent)
- Record count in the success message

### 4. User-Friendly Interface
- **Export Button**: Added to the Manage Classes screen (download icon in app bar)
- **Filter Cards**: Organized, easy-to-use filter selection
- **Applied Filters Summary**: Shows currently active filters
- **Clear Filters**: Quick button to reset all filters
- **Loading States**: Visual feedback during export process

## Use Cases

### Scenario 1: Subject-Specific Report
**Problem**: In one event with 5 subjects, a student attended 4 but was absent for the 5th.
**Solution**: Admin selects the specific subject from the dropdown and exports only that subject's attendance.

### Scenario 2: Teacher Performance
**Problem**: Admin needs attendance data for all classes taught by a specific teacher.
**Solution**: Admin selects the teacher from the dropdown and exports all their classes.

### Scenario 3: Date Range Analysis
**Problem**: Admin needs attendance data for a specific week or month.
**Solution**: Admin selects start and end dates to export attendance within that period.

### Scenario 4: Combined Filters
**Problem**: Admin needs attendance for "Arabic Grammar" taught by "Sheikh Ahmed" in December.
**Solution**: Admin selects subject, teacher, and date range together for precise results.

## Technical Implementation

### Files Modified
1. **lib/services/excel_service.dart**
   - Added `exportFilteredAttendanceToExcel()` method
   - Added `getUniqueSubjects()` helper method
   - Added `getUniqueTeachers()` helper method

2. **lib/screens/admin/manage_classes_screen.dart**
   - Added export button to app bar
   - Added navigation to export screen

### Files Created
1. **lib/screens/admin/export_attendance_screen.dart**
   - New screen with filter UI
   - Subject dropdown
   - Teacher dropdown
   - Date range pickers
   - Export button with loading state
   - Applied filters summary

## How to Use

1. **Navigate to Manage Classes** screen
2. **Click the download icon** in the app bar
3. **Select filters** as needed:
   - Choose a subject (optional)
   - Choose a teacher (optional)
   - Select start date (optional)
   - Select end date (optional)
4. **Click "Export to Excel"**
5. **File is saved** to Downloads folder with descriptive name
6. **Success message** shows file location and record count

## Benefits

✅ **Precise Data Extraction**: Get exactly the data you need
✅ **Time Saving**: No need to manually filter Excel files
✅ **Better Organization**: Descriptive file names for easy identification
✅ **Flexible Reporting**: Multiple filter combinations
✅ **User-Friendly**: Intuitive interface with clear feedback
✅ **Scalable**: Works efficiently with large datasets
