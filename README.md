# Smart Contract Public Fire Prevention and Safety Services

A comprehensive blockchain-based system for managing fire prevention and safety services in municipalities. This system consists of five interconnected smart contracts that handle different aspects of fire safety management.

## System Overview

### Contracts

1. **Fire Inspection Scheduling** (`fire-inspection-scheduling.clar`)
    - Coordinates safety inspections of commercial and residential properties
    - Tracks inspection schedules, results, and compliance status
    - Manages inspector assignments and property owner notifications

2. **Smoke Detector Installation Program** (`smoke-detector-program.clar`)
    - Manages free smoke alarm installation for low-income households
    - Tracks applications, eligibility verification, and installation scheduling
    - Maintains inventory of smoke detectors and installation records

3. **Fire Safety Education Coordination** (`fire-safety-education.clar`)
    - Schedules fire prevention programs in schools and communities
    - Manages educator assignments and program materials
    - Tracks attendance and program effectiveness

4. **Burn Permit Management** (`burn-permit-management.clar`)
    - Issues and tracks permits for controlled burns and outdoor fires
    - Manages permit applications, approvals, and compliance monitoring
    - Handles seasonal restrictions and weather-based permit suspensions

5. **Fire Hydrant Maintenance Tracking** (`fire-hydrant-maintenance.clar`)
    - Ensures fire hydrants are functional and accessible
    - Schedules regular maintenance and emergency repairs
    - Tracks hydrant locations, status, and maintenance history

## Key Features

- **Decentralized Management**: Each service area operates independently while maintaining data integrity
- **Access Control**: Role-based permissions for fire department staff, contractors, and citizens
- **Audit Trail**: Complete transaction history for compliance and accountability
- **Real-time Status**: Current status tracking for all safety equipment and services
- **Automated Scheduling**: Smart scheduling based on priorities and resource availability

## Data Security

- All sensitive data is stored on-chain with appropriate access controls
- Personal information is handled according to privacy regulations
- Audit logs provide complete traceability of all actions

## Getting Started

1. Deploy contracts to Stacks blockchain
2. Initialize with fire department administrator
3. Configure service areas and personnel
4. Begin registering properties, equipment, and scheduling services

## Testing

Run the test suite with:
\`\`\`bash
npm test
\`\`\`

## Deployment

Configure your deployment settings in `Clarinet.toml` and deploy using Clarinet CLI tools.
