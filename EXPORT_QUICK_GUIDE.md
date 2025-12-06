# Quick Reference Guide - Filtered Attendance Export

## For Admins: How to Export Attendance with Filters

### Step-by-Step Instructions

#### 1. Access the Export Screen
- Open the **Manage Classes** screen
- Tap the **download icon** (⬇️) in the top-right corner of the app bar
- The Export Attendance screen will open

#### 2. Select Your Filters (Optional)

**Subject Filter:**
- Tap the "Subject" dropdown
- Select a specific subject (e.g., "Arabic Grammar")
- Or leave as "All Subjects" to include all

**Teacher Filter:**
- Tap the "Teacher" dropdown  
- Select a specific teacher (e.g., "Sheikh Ahmed")
- Or leave as "All Teachers" to include all

**Date Range Filter:**
- Tap "From" button to select start date
- Tap "To" button to select end date
- Or leave unselected to include all dates

#### 3. Review Applied Filters
- Check the green "Applied Filters" card at the bottom
- Verify your selections are correct
- Use "Clear Filters" button to reset if needed

#### 4. Export the Data
- Tap the green "Export to Excel" button
- Wait for the export to complete (loading indicator will show)
- Success message will display the file location and record count

#### 5. Find Your File
- **Android**: Check the Downloads folder
- File name will include your filters for easy identification
- Example: `attendance_ArabicGrammar_SheikhAhmed_from_20251201_to_20251206_115604.xlsx`

---

## Common Use Cases

### Export All Attendance
**Filters:** None (leave all filters empty)
**Result:** Complete attendance records for all subjects, teachers, and dates

### Export for One Subject
**Filters:** Select subject only
**Example:** Subject = "Arabic Grammar"
**Result:** All attendance records for Arabic Grammar classes

### Export for One Teacher  
**Filters:** Select teacher only
**Example:** Teacher = "Sheikh Ahmed"
**Result:** All attendance records for classes taught by Sheikh Ahmed

### Export for Specific Date Range
**Filters:** Select start and end dates
**Example:** From = 1/12/2025, To = 6/12/2025
**Result:** All attendance records between these dates

### Export with Multiple Filters
**Filters:** Combine any filters
**Example:** Subject = "Arabic Grammar", Teacher = "Sheikh Ahmed", Date Range = 1/12 to 6/12
**Result:** Attendance for Arabic Grammar taught by Sheikh Ahmed in the specified date range

---

## Excel File Contents

Each exported file includes these columns:
1. **Date** - Date of attendance (DD/MM/YYYY)
2. **Time** - Time of attendance (HH:MM)
3. **Student Name** - Full name of the student
4. **Student ID** - Unique student identifier
5. **Subject** - Subject/class name
6. **Teacher** - Teacher name
7. **Status** - Present or Absent

---

## Tips & Best Practices

✅ **Use descriptive filters** - Combine filters for precise reports
✅ **Check the record count** - Verify you're getting the expected data
✅ **Note the file name** - It includes your filters for easy reference
✅ **Export regularly** - Keep backups of attendance data
✅ **Use date ranges** - For weekly or monthly reports

---

## Troubleshooting

**No records found?**
- Check if your filters are too restrictive
- Verify attendance has been marked for the selected criteria
- Try removing some filters to broaden the search

**File not downloading?**
- Check storage permissions
- Ensure you have enough storage space
- Try exporting a smaller date range

**Wrong data exported?**
- Review the "Applied Filters" summary before exporting
- Use "Clear Filters" and reselect your criteria
- Check that subject/teacher names match exactly

---

## Technical Notes

- Filters are applied in real-time
- Export includes only marked attendance (not all students)
- Date range is inclusive (includes both start and end dates)
- Subject and teacher filters are case-sensitive exact matches
- Files are saved with timestamp to prevent overwrites
