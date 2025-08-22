# Role Selection Implementation

## 🔧 **Issue Fixed**

### **Database Constraint Error:**
```
Error creating WhatsApp session: PostgrestException(message: null value in column "id" of relation "profiles" violates not-null constraint, code: 23502, details: Bad Request, hint: null)
```

### **User Request:**
"During signup, after OTP verification user must select role"
**Updated Request:** "role selection should be on same screen, Role Selection, Full Name, Create Account (button)"

## 🛠️ **Changes Made**

### **1. Fixed Database Constraint Error**
**File:** `lib/core/services/supabase_service.dart`

**Problem:** Profile creation was failing because the `id` field was null
**Solution:** Added the user ID from auth.users to the profile data

```dart
// Before
await client.from('profiles').insert(profileData);

// After
final profileDataWithId = {
  ...profileData,
  'id': signUpResponse.user!.id, // Use the auth user ID as profile ID
};
await client.from('profiles').insert(profileDataWithId);
```

### **2. Created Combined Profile Completion Screen**
**File:** `lib/features/auth/presentation/screens/role_selection_screen.dart`

**Features:**
- **Three Role Options:**
  - **Shopper** - Browse and purchase products from exhibitions
  - **Brand** - Showcase products and connect with customers  
  - **Organizer** - Create and manage exhibitions and events

- **Full Name Input:**
  - Text field for entering full name
  - Styled to match the app theme
  - Required field for account creation

- **Beautiful UI:**
  - Gradient background matching app theme
  - Role cards with icons and descriptions
  - Visual selection indicators
  - WhatsApp-themed design
  - Full name input field with proper styling

- **Functionality:**
  - Role selection with visual feedback
  - Full name input with validation
  - Account creation with selected role and full name
  - Navigation to home screen after account creation
  - Error handling and loading states
  - Button only enabled when both role and name are provided

### **3. Updated OTP Verification Flow**
**File:** `lib/features/auth/presentation/screens/whatsapp_otp_verification_screen.dart`

**Changes:**
- **Registration Flow:** After successful OTP verification, navigate to combined profile completion screen
- **Login Flow:** Remains unchanged (direct navigation to home)
- **Added Import:** RoleSelectionScreen import

```dart
// For registration flow
if (verificationResult['success']) {
  // Navigate to profile completion screen for new users
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => RoleSelectionScreen(
        phoneNumber: widget.phoneNumber,
      ),
    ),
  );
}
```

## 📱 **New User Flow**

### **Complete Signup Process:**
1. **Phone Number Entry** → User enters WhatsApp number
2. **OTP Verification** → User receives and enters 6-digit OTP
3. **Profile Completion** → User selects role AND enters full name
4. **Account Creation** → System creates account with selected role and full name
5. **Home Navigation** → User is taken to their dashboard

### **Existing User Flow:**
1. **Phone Number Entry** → User enters WhatsApp number
2. **OTP Verification** → User receives and enters 6-digit OTP
3. **Direct Login** → User is logged in and taken to dashboard

## 🎨 **UI Design**

### **Profile Completion Screen Features:**
- **Gradient Background** - Matches app theme (black to pink)
- **Header Section** - "Complete Your Profile" title with subtitle
- **Role Selection Section:**
  - **Role Cards** - Each role has:
    - **Icon** - Visual representation (shopping bag, store, event)
    - **Title** - Clear role name
    - **Description** - What the role can do
    - **Color Coding** - Blue (Shopper), Green (Brand), Orange (Organizer)
    - **Selection State** - Visual feedback when selected

- **Full Name Input Section:**
  - **Label** - "Full Name:" 
  - **Input Field** - Styled text field with:
    - **Placeholder** - "Enter your full name"
    - **Focus State** - Green border when focused
    - **Validation** - Required field

- **Interactive Elements:**
  - **Card Selection** - Tap to select role
  - **Name Input** - Type full name
  - **Create Account Button** - Only enabled when both role and name are provided
  - **Loading States** - Shows progress during account creation
  - **Error Handling** - Displays error messages if needed

## 🔧 **Technical Implementation**

### **Form Validation:**
```dart
// Button enabled only when both role and name are provided
onPressed: _selectedRole != null && _fullNameController.text.trim().isNotEmpty && !_isLoading ? _createAccount : null,
```

### **Account Creation with Full Name:**
```dart
final response = await SupabaseService.instance.createWhatsAppUser(
  phoneNumber: widget.phoneNumber,
  userData: {
    'role': _selectedRole,
    'full_name': _fullNameController.text.trim(),
    'phone': widget.phoneNumber,
    'phone_verified': true,
    // ... other user data
  },
);
```

### **Controller Management:**
```dart
final TextEditingController _fullNameController = TextEditingController();

@override
void dispose() {
  _fullNameController.dispose();
  super.dispose();
}
```

## ✅ **Benefits**

### **For Users:**
- **Streamlined Process** - Everything on one screen
- **Clear Role Understanding** - Users know what each role means
- **Complete Profile** - Full name is captured during signup
- **Visual Appeal** - Beautiful, intuitive interface
- **Flexibility** - Can change role and details later in profile settings

### **For App:**
- **Proper User Segmentation** - Users are correctly categorized
- **Complete User Data** - Full name is available from signup
- **Better UX** - Single-screen profile completion
- **Data Integrity** - Fixed database constraint issues
- **Scalability** - Easy to add more fields in the future

## 🚀 **Expected Results**

### **After Implementation:**
1. ✅ **No More Database Errors** - Profile creation works correctly
2. ✅ **Combined Profile Screen** - Role selection and full name on same screen
3. ✅ **Complete User Data** - Both role and full name captured
4. ✅ **Proper User Flow** - Streamlined signup process for new users
5. ✅ **Session Creation** - Users get proper sessions after account creation
6. ✅ **Dashboard Access** - Users reach their role-specific dashboard

The profile completion screen now combines role selection and full name input on a single screen, providing a streamlined user experience! 🎉
