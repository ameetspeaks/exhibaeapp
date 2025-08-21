# Shopper Features Documentation

## Overview

The shopper features provide a complete experience for users who want to discover, explore, and interact with exhibitions and brands. The shopper role is designed for attendees and visitors who want to browse exhibitions, mark their attendance, and favorite brands.

## Features

### 1. Home Screen (`ShopperHomeScreen`)
- **Featured Exhibitions**: Displays highlighted exhibitions in a horizontal scrollable list
- **Upcoming Events**: Shows upcoming exhibitions in a vertical list format
- **Category Filter**: Allows filtering by exhibition categories
- **Pull-to-refresh**: Refresh data by pulling down
- **Notification indicator**: Shows unread notifications

### 2. Explore Screen (`ShopperExploreScreen`)
- **Dual Tab Interface**: 
  - Exhibitions tab: Browse all available exhibitions
  - Brands tab: Browse all registered brands
- **Search Functionality**: Search exhibitions and brands by name or description
- **Advanced Filtering**: Filter by category, location, and date range
- **Interactive Cards**: 
  - Mark exhibitions as attending
  - Favorite/unfavorite exhibitions and brands
  - View detailed information

### 3. Favorites Screen (`ShopperFavoritesScreen`)
- **Dual Tab Interface**:
  - Exhibitions tab: View favorited exhibitions
  - Brands tab: View favorited brands
- **Remove from Favorites**: Easy removal with visual feedback
- **Empty States**: Helpful messages when no favorites exist
- **Navigation to Explore**: Quick access to discover more content

### 4. Profile Screen (`ShopperProfileScreen`)
- **User Information**: Display profile picture, name, email, and role
- **Settings Section**:
  - Notifications preferences
  - Privacy settings
  - Language settings
  - Dark mode toggle
- **Support Section**:
  - Help & Support
  - About app
  - Terms of Service
  - Privacy Policy
- **Sign Out**: Secure logout functionality

## Navigation

The shopper dashboard uses a bottom navigation bar with four main tabs:

1. **Home** - Featured and upcoming exhibitions
2. **Explore** - Browse exhibitions and brands
3. **Favorites** - Saved exhibitions and brands
4. **Profile** - User settings and account management

## Database Schema

### New Tables

#### `exhibition_attendees`
- Tracks which users are attending which exhibitions
- Prevents duplicate attendance records
- Includes RLS policies for security

#### `brand_favorites`
- Tracks which users have favorited which brands
- Prevents duplicate favorite records
- Includes RLS policies for security

### Existing Tables Used
- `exhibitions` - Exhibition data
- `profiles` - User and brand profile data
- `exhibition_favorites` - Existing favorites functionality

## Widgets

### Featured Exhibition Card
- Horizontal card design for featured exhibitions
- Image, title, location, date, and action buttons
- Mark attending and favorite functionality

### Upcoming Event Card
- Compact list item design
- Image, title, location, date, and quick actions
- Optimized for vertical scrolling

### Exhibition Card
- Full-featured card for explore screen
- Category badges, favorite overlay, and detailed information
- Multiple action buttons

### Brand Card
- Brand information display
- Logo, company name, contact details
- Favorite and view details functionality

### Category Filter
- Horizontal scrollable filter chips
- Visual selection states
- Easy category switching

### Search Bar
- Clean, modern search interface
- Clear functionality
- Consistent with app theme

### Filter Bottom Sheet
- Comprehensive filtering options
- Category, location, and date range filters
- Reset and apply functionality

## Color Scheme

The shopper features use the consistent app color scheme:

- **Primary Maroon**: `#4B1E25` - Main brand color
- **Background Peach**: `#F5E4DA` - Background color
- **Secondary Warm**: `#E6C5B6` - Secondary elements
- **Accent Gold**: `#E6B17A` - Accent and highlights
- **Border Light Gray**: `#C1C1C0` - Borders and dividers

## Typography

Uses the Inter font family with consistent text styles:
- Headlines: Bold, primary maroon color
- Body text: Regular weight, dark charcoal color
- Captions: Medium weight, medium gray color

## User Experience Features

### Loading States
- Circular progress indicators during data loading
- Consistent loading animations

### Empty States
- Helpful messages when no data is available
- Call-to-action buttons to explore content

### Error Handling
- User-friendly error messages
- Retry functionality for failed operations

### Pull-to-Refresh
- Swipe down to refresh data
- Visual feedback during refresh

### Responsive Design
- Adapts to different screen sizes
- Consistent spacing and layout

## Integration Points

### Authentication
- Integrates with existing Supabase authentication
- Role-based access control
- Secure user sessions

### Navigation
- Seamless integration with existing app navigation
- Consistent routing patterns
- Deep linking support

### Data Management
- Real-time data updates
- Optimistic UI updates
- Efficient data caching

## Future Enhancements

### Planned Features
- Push notifications for favorite exhibitions
- Social sharing functionality
- Exhibition recommendations
- Advanced search filters
- Offline support
- Multi-language support

### Performance Optimizations
- Image lazy loading
- Pagination for large lists
- Data prefetching
- Background sync

## Testing Considerations

### Unit Tests
- Widget functionality
- Data management
- User interactions

### Integration Tests
- Navigation flows
- Data persistence
- Authentication flows

### User Acceptance Tests
- End-to-end user journeys
- Cross-device compatibility
- Performance benchmarks

## Deployment Notes

### Database Migration
- Run the `create_shopper_tables.sql` migration
- Verify RLS policies are active
- Test data access permissions

### App Configuration
- Update user role handling
- Configure navigation routes
- Test authentication flows

### Monitoring
- Track user engagement metrics
- Monitor performance indicators
- Log error rates and user feedback
