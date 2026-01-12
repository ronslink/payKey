# Properties & Geofencing Feature

## Overview
Property/location management with geofencing for location-based time tracking validation.

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/properties` | List all properties |
| POST | `/properties` | Create property |
| GET | `/properties/:id` | Get property details |
| PATCH | `/properties/:id` | Update property |
| DELETE | `/properties/:id` | Delete property |

## Property Model
```json
{
  "name": "Main Office",
  "address": "123 Business St",
  "city": "Nairobi",
  "type": "OFFICE",
  "latitude": -1.2921,
  "longitude": 36.8219,
  "geofenceRadius": 100
}
```

## Property Types
- `OFFICE` - Office location
- `SITE` - Construction/work site
- `RESIDENCE` - Private residence
- `WAREHOUSE` - Storage facility

## Geofencing

### Purpose
Validate employee clock-in/out location against assigned property.

### How It Works
1. Property has lat/long coordinates and radius (meters)
2. Employee clocks in with GPS location
3. System checks if employee is within geofence
4. Clock-in allowed if within radius, flagged if outside

### Geofence Configuration
| Field | Type | Description |
|-------|------|-------------|
| `latitude` | decimal | Property latitude |
| `longitude` | decimal | Property longitude |
| `geofenceRadius` | integer | Radius in meters (default: 100) |

## Worker Assignment
Workers assigned to properties via `propertyId` field on worker record.

## Mobile UI
- **Properties**: `mobile/lib/features/properties/presentation/pages/`
- Map picker for coordinates
- Radius slider for geofence

## Database Entities
- `Property` - `backend/src/modules/properties/entities/property.entity.ts`

## Current Configuration Status
- ✅ Property CRUD operations
- ✅ Worker assignment to properties
- ✅ Filter workers by property
- ✅ Location capture on clock-in

## Known Gaps
| Gap | Status |
|-----|--------|
| Geofence enforcement | ⚠️ Location captured, validation partial |
| Map UI for property creation | ⚠️ Basic implementation |
| Geofence alerts | ❌ Not implemented |
