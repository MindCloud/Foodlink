# FoodLink - Complete System Workflow

## Overview
FoodLink connects **Food Donors** with surplus food to **Charities** who feed people in need. The system uses an **Intelligent Matching Algorithm (IMA)** to optimally match donations to charities based on distance, spoilage risk, and fairness.

---

## 1. FOOD DONOR Workflow

### Role
Individuals, restaurants, hotels, or events with surplus food to donate.

### Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. REGISTER/LOGIN                                              │
│     • Sign up with Firebase Auth (email/password)                 │
│     • Select "Food Donor" role                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. DASHBOARD OVERVIEW                                          │
│     • View impact statistics (total kg donated, people fed)       │
│     • See badges earned (First Rescue, Eco Hero, etc.)            │
│     • View past donations with real-time status                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. LOG SURPLUS FOOD                                            │
│     • Select food type (Rice & Curry, Biryani, Bread, etc.)       │
│     • Enter quantity (kg)                                         │
│     • Capture GPS location (required for matching)                │
│     • Set pickup time window                                      │
│     • Toggle cold storage requirement                             │
│     • Set expiry time (1-24 hours slider)                         │
│     • Add optional photo & notes                                  │
│     • Submit to Firestore                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. DONATION STATUS TRACKING                                    │
│     • "Logged" → Submitted to system                              │
│     • "Claimed" → Charity claimed for pickup                        │
│     • "Picked Up" → Food collected                                │
│     • "Delivered" → Food received by charity                      │
│     • Can edit/delete while status is "Logged"                    │
└─────────────────────────────────────────────────────────────────┘
```

### Backend Connection
| Action | Backend API/Service | Data Stored |
|--------|---------------------|-------------|
| Register | Firebase Auth | `users/{uid}` |
| Log Donation | FirestoreService.createDonation() | `donations/{id}` |
| View Donations | Firestore real-time stream | `donations` where `donorId == uid` |
| Delete Donation | FirestoreService.deleteDonation() | Removes from `donations/{id}` |
| Get Stats | Firestore aggregation | Calculates from `donations` collection |

### Database Schema (Donations Collection)
```javascript
donations/{donationId} {
  donorId: "user_uid",           // Reference to donor
  donorEmail: "user@email.com",
  foodType: "Cooked Rice & Curry",
  quantity: "12 kg",
  quantityKg: 12.0,               // Numeric for calculations
  latitude: 6.9319,               // GPS location
  longitude: 79.8478,
  pickupFrom: "6:00 PM",
  pickupTo: "7:00 PM",
  coldRequired: true,             // Needs refrigeration
  expiryHours: 4.0,               // Hours until spoilage
  notes: "Vegetarian, no nuts",
  imageUrl: "https://storage...", // Firebase Storage URL
  status: "Logged",               // Logged|Claimed|PickedUp|Delivered
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

## 2. CHARITY Workflow

### Role
Organizations that feed people: Old Age Homes, Orphanages, Community Kitchens, Shelters.

### Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. REGISTER/LOGIN                                              │
│     • Sign up with Firebase Auth                                  │
│     • Select "Charity" role                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. CHARITY PROFILE REGISTRATION (Required)                       │
│     • Enter charity name, address, phone                          │
│     • Select charity type (Old Age Home, Orphanage, etc.)         │
│     • Capture GPS location (required for matching)                │
│     • Toggle "Has Cold Storage" capability                        │
│     • Set daily capacity (kg)                                     │
│     • Add description                                             │
│     • Submit to Firestore                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. VIEW MATCHED DONATIONS (IMA Powered)                        │
│     • System shows donations ranked by IMA score                  │
│     • Each match shows:                                           │
│       - Distance (km)                                             │
│       - Spoilage risk (0-1)                                       │
│       - IMA Score (0-100)                                         │
│       - Matching reason (e.g., "High Nutritional Fit")            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. CLAIM DONATION (Tier 1 - Free Pickup)                       │
│     • Browse available donations                                  │
│     • View donor location on map                                  │
│     • Click "Claim for Free Pickup"                                │
│     • System updates donation status to "Claimed"                   │
│     • Pickup must happen by 5:30 PM                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. TIER 2 - RIDER DELIVERY (If not claimed by 5:30 PM)         │
│     • Unclaimed donations move to Tier 2                            │
│     • Delivery rider picks up and delivers                          │
│     • Charity receives food at door                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. RECEIVE & CONFIRM                                           │
│     • Charity receives food                                       │
│     • Confirms receipt in app                                     │
│     • System increments "receivedToday" counter                   │
└─────────────────────────────────────────────────────────────────┘
```

### Backend Connection
| Action | Backend API/Service | Data Stored |
|--------|---------------------|-------------|
| Register Profile | FirestoreService.createCharity() | `charities/{id}` |
| Get Matches | IMA API `/ima/batch` + Firestore | Fetches `donations` + processes via IMA |
| Claim Donation | Firestore update + create match | Updates `donations/{id}`, creates `matches/{id}` |
| View on Map | Google Maps API | Shows route from donor to charity |

### IMA (Intelligent Matching Algorithm) Backend Flow
```
┌─────────────────────────────────────────────────────────────────┐
│  FLUTTER APP (Charity Dashboard)                                  │
│  1. Fetch available donations from Firestore                      │
│  2. Send to Python Flask Backend                                  │
└─────────────────────────────────────────────────────────────────┘
                              │ POST /ima/batch
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  PYTHON BACKEND (Flask)                                           │
│  1. Receive donations + charity data                              │
│  2. For each donation:                                              │
│     • Calculate Haversine distance (8-12km geofence)                │
│     • Calculate spoilage risk (expiry + distance factor)            │
│     • Apply Adaptive MCDM weights based on expiry                   │
│       - <2h: Priority on spoilage (60%)                           │
│       - 2-6h: Balanced (40% spoilage, 30% distance, 30% fairness) │
│       - >6h: Priority on fairness (50%)                           │
│  3. Rank charities by final score                                   │
│  4. Return best match with reason                                   │
└─────────────────────────────────────────────────────────────────┘
                              │ Returns match results
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  FLUTTER APP                                                      │
│  • Display ranked list with IMA scores                              │
│  • Show spoilage risk indicators                                    │
│  • Allow charity to claim top matches                               │
└─────────────────────────────────────────────────────────────────┘
```

### Database Schema (Charities Collection)
```javascript
charities/{charityId} {
  userId: "user_uid",              // Reference to user
  email: "charity@email.com",
  name: "Hope Shelter",
  address: "123 Main St, Colombo",
  phone: "+94 77 123 4567",
  charityType: "Old Age Home",    // Orphanage|Community Kitchen|etc.
  latitude: 6.9319,
  longitude: 79.8478,
  hasColdStorage: true,
  capacityRemaining: 50,          // Daily capacity in kg
  receivedToday: 3,               // Counter (resets daily)
  totalReceived: 45,              // Lifetime counter
  description: "Feeding elderly...",
  isActive: true,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Database Schema (Matches Collection)
```javascript
matches/{matchId} {
  donationId: "donation_id",
  charityId: "charity_id",
  matchedBy: "user_uid",
  score: 0.87,                     // IMA score (0-1)
  distanceKm: 9.2,
  spoilageRisk: 0.15,
  status: "Claimed",              // Claimed|PickedUp|Delivered
  createdAt: Timestamp
}
```

---

## 3. DELIVERY RIDER Workflow

### Role
Third-party delivery partners who pick up unclaimed donations and deliver to charities.

### Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. LOGIN (Through Admin or Partner Portal)                     │
│     • Rider authenticates via Firebase Auth                       │
│     • Admin assigns "rider" role                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. VIEW TIER 2 ASSIGNMENTS                                     │
│     • See donations that passed 5:30 PM deadline                  │
│     • Each assignment shows:                                        │
│       - Pickup location (donor GPS)                               │
│       - Delivery location (charity GPS)                           │
│       - Food details and expiry                                   │
│       - Optimized route                                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. PICKUP & DELIVERY                                           │
│     • Navigate to donor location (Google Maps integration)          │
│     • Collect food, confirm pickup                                  │
│     • Navigate to charity location                                  │
│     • Deliver food, get confirmation signature                      │
│     • Update status to "Delivered"                                │
└─────────────────────────────────────────────────────────────────┘
```

### Backend Connection
| Action | Backend API/Service | Data Stored |
|--------|---------------------|-------------|
| View Assignments | Firestore query | Fetches `donations` where `status == "Tier2"` |
| Confirm Pickup | Firestore update | Updates `donations/{id}` status |
| Confirm Delivery | Firestore update | Updates `donations/{id}`, creates delivery record |
| Navigation | Google Maps API | Shows route on map screen |

### Database Schema (Rider Assignments)
```javascript
riderAssignments/{assignmentId} {
  riderId: "rider_uid",
  donationId: "donation_id",
  charityId: "charity_id",
  pickupLat: 6.8500,
  pickupLon: 79.8600,
  deliveryLat: 6.9319,
  deliveryLon: 79.8478,
  status: "Assigned",            // Assigned|PickedUp|Delivered
  assignedAt: Timestamp,
  pickedUpAt: Timestamp,
  deliveredAt: Timestamp
}
```

---

## 4. FINANCIAL SPONSOR Workflow

### Role
Organizations or individuals who fund the platform operations, rider costs, or specific campaigns.

### Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. REGISTER/LOGIN                                                │
│     • Sign up with Firebase Auth                                  │
│     • Select "Financial Sponsor" role                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. VIEW IMPACT DASHBOARD                                       │
│     • Total donations funded                                      │
│     • Kilograms of food rescued                                   │
│     • People fed through sponsorship                              │
│     • CO₂ emissions prevented                                     │
│     • Cost per meal delivered                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. MAKE CONTRIBUTION                                           │
│     • One-time donation                                           │
│     • Monthly subscription                                        │
│     • Sponsor specific campaign (e.g., "Weekend Meals for Kids")  │
│     • Payment via Stripe/PayPal integration                       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. TRACK USAGE                                                 │
│     • See which donations their funds supported                   │
│     • View delivery receipts and confirmations                    │
│     • Download tax receipts                                       │
│     • Receive impact reports                                      │
└─────────────────────────────────────────────────────────────────┘
```

### Backend Connection
| Action | Backend API/Service | Data Stored |
|--------|---------------------|-------------|
| View Impact | Firestore aggregation | Calculates from `donations` + `sponsorships` |
| Make Payment | Stripe/PayPal API | Creates `transactions/{id}` |
| Track Usage | Firestore queries | Joins `transactions` + `donations` |

### Database Schema (Sponsorships Collection)
```javascript
sponsorships/{sponsorshipId} {
  sponsorId: "user_uid",
  amount: 5000.00,                // Amount in LKR
  currency: "LKR",
  type: "OneTime",                // OneTime|Monthly|Campaign
  campaign: "Weekend Meals",      // Optional campaign name
  paymentMethod: "Card",
  transactionId: "txn_abc123",
  status: "Completed",            // Pending|Completed|Failed
  fundedDonations: ["donation1", "donation2"],
  impactKg: 125.5,                // Kg of food funded
  peopleFed: 45,
  createdAt: Timestamp
}
```

---

## Backend Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     FRONTEND (Flutter)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐      │
│  │ Donor App    │  │ Charity App  │  │ Sponsor Portal   │      │
│  └──────────────┘  └──────────────┘  └──────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Firebase Auth (Login)
                              │ Firestore (Data Storage)
                              │ Firebase Storage (Images)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BACKEND SERVICES                              │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  FIREBASE FIRESTORE (Primary Database)                    │   │
│  │  • donations, charities, users, matches                  │   │
│  │  • sponsorships, riderAssignments                        │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              │ HTTP Requests                     │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  PYTHON FLASK API (IMA Engine)                          │   │
│  │  • POST /ima - Single match                             │   │
│  │  • POST /ima/batch - Batch matches                      │   │
│  │  • GET /health - Health check                             │   │
│  │  • POST /evaluate - Algorithm evaluation                  │   │
│  │  • GET /report - Generate reports                         │   │
│  │                                                         │   │
│  │  Components:                                            │   │
│  │  • ima_engine.py - Core matching algorithm                │   │
│  │  • mcdm_allocator.py - Multi-criteria decision making     │   │
│  │  • baselines.py - Comparison algorithms                   │   │
│  │  • evaluate.py - Evaluation metrics                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│                              │ Optional                            │
│                              ▼                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  PAYMENT GATEWAY (Stripe/PayPal)                        │   │
│  │  • Process sponsor payments                               │   │
│  │  • Store transaction records                              │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Security Rules Summary

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users: Manage own profile only
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Donations: Create if auth, edit only if donor
    match /donations/{donationId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              resource.data.donorId == request.auth.uid;
    }
    
    // Charities: Create if auth, edit only if owner
    match /charities/{charityId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              resource.data.userId == request.auth.uid;
    }
    
    // Matches: Auth required
    match /matches/{matchId} {
      allow read, write: if request.auth != null;
    }
    
    // Sponsorships: Manage own
    match /sponsorships/{sponsorshipId} {
      allow read, write: if request.auth != null && 
                          resource.data.sponsorId == request.auth.uid;
    }
  }
}
```

---

## Data Flow Summary

| User Action | Frontend | Backend | Database |
|-------------|----------|---------|----------|
| Donor logs food | Flutter Form → Validation | FirestoreService.createDonation() | `donations/{id}` |
| Charity views matches | Flutter Dashboard | IMA API + Firestore Query | `donations` + IMA processing |
| Charity claims | Flutter Button | Firestore Update + Create Match | `donations/{id}` + `matches/{id}` |
| Rider delivers | Flutter Confirmation | Firestore Update | `donations/{id}` + `riderAssignments/{id}` |
| Sponsor donates | Flutter Payment Form | Stripe API + Firestore | `sponsorships/{id}` |
| View reports | Flutter Report Screen | IMA API /report endpoint | Aggregates from all collections |

---

*Last Updated: April 2026*
