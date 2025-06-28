# Logistica

**Logistics Management Centre**  
Salesforce-native app to orchestrate global shipment operations across two orgs:

- **Org A** – Logistics Centre (Logistica)
- **Org B** – Carrier Processor

## Current Data Model

### ShipmentRequest\_\_c

Custom object to represent each shipment request.

| Field Name         | API Name                | Data Type | Description                      |
| ------------------ | ----------------------- | --------- | -------------------------------- |
| Origin             | `Origin__c`             | Picklist  | Shipment origin country          |
| Destination        | `Destination__c`        | Picklist  | Shipment destination country     |
| Carrier            | `Carrier__c`            | Text      | Carrier name.                    |
| Status             | `Status__c`             | Picklist  | Shipment lifecycle state         |
| Tracking ID        | `Tracking_ID__c`        | Text      | External carrier tracking number |
| Estimated Delivery | `Estimated_Delivery__c` | Date      | Projected delivery date.         |
| Region             | `Region__c`             | Picklist  | Derived shipping region          |
| ShipmentRequest Id | `ShipmentRequest_Id__c` | Text      | External Id from other system.   |

### User (Custom Field)

| Field Name | API Name    | Data Type | Description                          |
| ---------- | ----------- | --------- | ------------------------------------ |
| Region     | `Region__c` | Picklist  | Region to which the user is assigned |

---

### Territory\_\_c

Manage region‐to‐country mappings in a hierarchy.

| Field Name | API Name     | Data Type | Description                                                        |
| ---------- | ------------ | --------- | ------------------------------------------------------------------ |
| Country    | `Country__c` | Picklist  | Country name (uses Country global value set)                       |
| Region     | `Region__c`  | Lookup    | Lookup back to a **Region**–type territory record                  |
| Type       | `Type__c`    | Picklist  | `Region` or `Country` – distinguishes parent regions from children |

- **Hierarchy**
    - Region records have `Type__c = Region` and no parent.
    - Country records have `Type__c = Country` and a lookup parent to their Region record.
    - On the Region detail page, all child Country records appear in a related list.
![Screenshot 2025-06-28 at 22 52 30](https://github.com/user-attachments/assets/8d1fbf52-c207-4e69-a6fd-87f56e362f54)

---

## Global Value Sets

Two global value sets are used for maintainable picklists:

1. **Country**
    - Referenced by:
        - `ShipmentRequest__c.Origin__c`
        - `ShipmentRequest__c.Destination__c`
        - `Territory__c.Country__c`

2. **Region**
    - Referenced by:
        - `ShipmentRequest__c.Region__c`
        - `User.Region__c`

---

## Flows

### Assign_Region_On_Shipment_Request_Insert

- **Type:** Record-Triggered Flow (Before Insert on `ShipmentRequest__c`)
- **Logic:**
    1. **Trigger:** Runs before insert of a new ShipmentRequest record
    2. **Lookup:** Query `Territory__c` where `Country__c` equals the incoming `Destination__c`
    3. **Populate:**
        - Set `Region__c` on the new `ShipmentRequest__c` to the matched territory’s region
        - Set `Status__c` to **Assigned to Agent**
    4. **Optional:** Assign `OwnerId` to a region-specific queue

### Publish_Shipment_Request_Event_on_Insert_and_Update

- **Type:** Record-Triggered Flow (After Insert & After Update on `ShipmentRequest__c`)
- **Logic:**
    1. Fire only when `Region__c` on the record is populated
    2. Publish a **Platform Event** record of type `ShipmentRequest_Event__e`
        - Map `Region__c` from the source record into the event’s `Region__c` field
    3. Enables subscribers (e.g., LWCs) to receive real-time notifications

---

## Platform Events & Notifications

### ShipmentRequest_Event\_\_e

- **Fields:**
    - `Region__c` (Picklist) – carries the shipping region to subscribers

    ***

## Integration & Named Credentials

### Org A (Logistica)

- **External Client Application:** `Logistica_Client_App`
    - OAuth 2.0 Client Credentials Flow
    - API scope enabled
    - Runs as a dedicated integration user
- **External Credential:** `CarrierAPIExtCredential`
    - Uses OAuth 2.0 (Client Credentials)
- **Named Credential:** `CarrierAPICredential`

### Org B (Carrier Org)

- **External Client Application:** `ShipmentRequest`
    - OAuth 2.0 Client Credentials Flow
    - API scope enabled
    - Runs as a dedicated integration user
- **External Credential:** `LogisticaExtCredential`
    - Uses OAuth 2.0 Client Credentials
- **Named Credential:** `LogisticaCredential`

### Why Client Credentials OAuth with Named Credentials?

- **Secure, headless integration:** No user interaction required once set up
- **Least-privilege access:** Integration user with only required API permissions
- **Managed secrets:** Client ID/Secret stored in Named Credentials, never hard-coded

---

## Carrier API & Callback Logic (Org B)

1. **Endpoint:** `POST /services/apexrest/CarrierAPI`
    - Request body contains `shipmentRequestId` (external ID)
2. **Processing:** Enqueue a Queueable job for dispatch
3. **Queueable Job:**
    - Simulates dispatch logic
    - On **Success:**
        - HTTP PATCH to Org A using `LogisticaCredential`
        - Updates `Status__c = Dispatched`, `Tracking_ID__c`, `Estimated_Delivery__c`
    - On **Failure:**
        - Retry up to 3 times (re-enqueue)
        - _(Future)_ After 3 failures, log to a `Future_Job__c` object for rescheduling at a later time

4. **Org A Dispatch Trigger (Queueable)**
    - When a record’s `Status__c` → **Ready for Dispatch**, enqueue a Queueable to call Org B’s Carrier API
    - _(Future)_ We could have a daily scheduled batch querying all “Ready for Dispatch” records and calling Org B's Carrier API

### Subscription in LWC

- In `shipmentRequestDatatable` component:
    - Use `lightning/empApi` to subscribe to `/event/ShipmentRequest_Event__e`
    - On event receipt for current agents region, datatable is refreshed
    - Ensures agents see new or updated shipments immediately without manual refresh

## Lightning UI

### Lightning App and Page

- **App:** `Logistica_App` (Lightning App)
- **App Page:** `Logistica`
    - Added as a navigation item in **Logistica_App**

### Lightning Web Component

- **Component Name:** `shipmentRequestDatatable`
- **Functionality:**
    - Displays a `datatable` of `ShipmentRequest__c` records for the logged-in user’s region
    - Columns:
        - ShipmentRequest Number
        - Destination
        - Carrier
        - Status
        - Tracking ID
        - Estimated Delivery
    - **Status Filter:** Status filter above the table to filter rows by one or more `Status__c` values
    - **Real-Time Updates:** Subscribes to `ShipmentRequest_Event__e` for automatic updates
    - **Visual Styling:** Conditional row highlighting (green for “Assigned to Agent”, yellow for “In Review” + preview icon,)
      
![Screenshot 2025-06-28 at 22 54 45](https://github.com/user-attachments/assets/af847ce6-4275-4d3d-a081-4f2c11b8e39e)

---

## Integration Diagram
![logistica drawio](https://github.com/user-attachments/assets/bac8476c-6098-439c-a548-bf8b6596b62a)

