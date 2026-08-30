-- CreateTable
CREATE TABLE "tbprivileges" (
    "PK_privilege" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "privilege" TEXT NOT NULL,
    "privilegeCode" TEXT NOT NULL,
    "privilegeType" TEXT NOT NULL,
    "description" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "tbcitizens" (
    "PK_citizen" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "CI" TEXT,
    "phoneNumber" TEXT NOT NULL,
    "email" TEXT,
    "password" TEXT,
    "profileImage" TEXT,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "actionHistory" JSONB
);

-- CreateTable
CREATE TABLE "tbinstitutiontypes" (
    "PK_institutionType" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB
);

-- CreateTable
CREATE TABLE "tbinstitutions" (
    "PK_institution" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_institutionType" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "acronym" TEXT,
    "phoneNumber" TEXT,
    "email" TEXT,
    "address" TEXT,
    "latitude" REAL,
    "longitude" REAL,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "actionHistory" JSONB,
    CONSTRAINT "tbinstitutions_FK_institutionType_fkey" FOREIGN KEY ("FK_institutionType") REFERENCES "tbinstitutiontypes" ("PK_institutionType") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbsubinstitutions" (
    "PK_subinstitution" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_institution" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT,
    "phoneNumber" TEXT,
    "email" TEXT,
    "address" TEXT,
    "latitude" REAL,
    "longitude" REAL,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "actionHistory" JSONB,
    CONSTRAINT "tbsubinstitutions_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions" ("PK_institution") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbusers" (
    "PK_user" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_privilege" INTEGER NOT NULL,
    "FK_institution" INTEGER,
    "FK_subinstitution" INTEGER,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "actionHistory" JSONB,
    CONSTRAINT "tbusers_FK_privilege_fkey" FOREIGN KEY ("FK_privilege") REFERENCES "tbprivileges" ("PK_privilege") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbusers_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions" ("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbusers_FK_subinstitution_fkey" FOREIGN KEY ("FK_subinstitution") REFERENCES "tbsubinstitutions" ("PK_subinstitution") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbdevices" (
    "PK_device" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_citizen" INTEGER NOT NULL,
    "pushToken" TEXT,
    "device" JSONB NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "tbdevices_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens" ("PK_citizen") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbusersdevices" (
    "PK_device" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_user" INTEGER NOT NULL,
    "pushToken" TEXT,
    "device" JSONB NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "tbusersdevices_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers" ("PK_user") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbresourcetypes" (
    "PK_resourceType" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB
);

-- CreateTable
CREATE TABLE "tbinstitutionservices" (
    "PK_institutionService" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_institution" INTEGER NOT NULL,
    "FK_resourceType" INTEGER NOT NULL,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB,
    CONSTRAINT "tbinstitutionservices_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions" ("PK_institution") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbinstitutionservices_FK_resourceType_fkey" FOREIGN KEY ("FK_resourceType") REFERENCES "tbresourcetypes" ("PK_resourceType") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbunits" (
    "PK_unit" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_institution" INTEGER NOT NULL,
    "FK_subinstitution" INTEGER,
    "FK_resourceType" INTEGER NOT NULL,
    "unitCode" TEXT NOT NULL,
    "unitName" TEXT NOT NULL,
    "phoneNumber" TEXT,
    "status" TEXT NOT NULL,
    "isAvailable" BOOLEAN NOT NULL DEFAULT true,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "actionHistory" JSONB,
    CONSTRAINT "tbunits_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions" ("PK_institution") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbunits_FK_subinstitution_fkey" FOREIGN KEY ("FK_subinstitution") REFERENCES "tbsubinstitutions" ("PK_subinstitution") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbunits_FK_resourceType_fkey" FOREIGN KEY ("FK_resourceType") REFERENCES "tbresourcetypes" ("PK_resourceType") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencytypes" (
    "PK_emergencyType" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT,
    "status" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB
);

-- CreateTable
CREATE TABLE "tbemergencies" (
    "PK_emergency" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_citizen" INTEGER,
    "FK_emergencyType" INTEGER,
    "FK_parentEmergency" INTEGER,
    "emergencyCode" TEXT NOT NULL,
    "priority" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "isMainEmergency" BOOLEAN NOT NULL DEFAULT true,
    "reportCount" INTEGER NOT NULL DEFAULT 1,
    "description" TEXT,
    "affectedPersons" INTEGER,
    "affectedAnimals" INTEGER,
    "trappedPersons" INTEGER,
    "missingPersons" INTEGER,
    "reportedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "acceptedAt" DATETIME,
    "resolvedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "actionHistory" JSONB,
    CONSTRAINT "tbemergencies_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens" ("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbemergencies_FK_emergencyType_fkey" FOREIGN KEY ("FK_emergencyType") REFERENCES "tbemergencytypes" ("PK_emergencyType") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbemergencies_FK_parentEmergency_fkey" FOREIGN KEY ("FK_parentEmergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbaisessions" (
    "PK_aiSession" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_citizen" INTEGER NOT NULL,
    "FK_emergency" INTEGER,
    "sessionStatus" TEXT NOT NULL,
    "initialIntent" TEXT,
    "latitude" REAL,
    "longitude" REAL,
    "startedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" DATETIME,
    CONSTRAINT "tbaisessions_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens" ("PK_citizen") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbaisessions_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencyreports" (
    "PK_report" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "FK_citizen" INTEGER,
    "reportChannel" TEXT NOT NULL,
    "description" TEXT,
    "latitude" REAL NOT NULL,
    "longitude" REAL NOT NULL,
    "isLinkedByAI" BOOLEAN NOT NULL DEFAULT false,
    "linkingConfidence" REAL,
    "distanceMetersFromMain" REAL,
    "reportedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbemergencyreports_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyreports_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens" ("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencylocations" (
    "PK_location" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "latitude" REAL NOT NULL,
    "longitude" REAL NOT NULL,
    "accuracy" REAL,
    "address" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbemergencylocations_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbcalls" (
    "PK_call" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "callType" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "startedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "answeredAt" DATETIME,
    "endedAt" DATETIME,
    "durationSeconds" INTEGER,
    "transcription" TEXT,
    "audioUrl" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actionHistory" JSONB,
    CONSTRAINT "tbcalls_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencyrooms" (
    "PK_room" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "roomCode" TEXT NOT NULL,
    "isOpen" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "closedAt" DATETIME,
    CONSTRAINT "tbemergencyrooms_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencyroommembers" (
    "PK_roomMember" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_room" INTEGER NOT NULL,
    "FK_citizen" INTEGER,
    "FK_user" INTEGER,
    "FK_institution" INTEGER,
    "FK_unit" INTEGER,
    "memberRole" TEXT NOT NULL,
    "joinedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "leftAt" DATETIME,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    CONSTRAINT "tbemergencyroommembers_FK_room_fkey" FOREIGN KEY ("FK_room") REFERENCES "tbemergencyrooms" ("PK_room") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyroommembers_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens" ("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyroommembers_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers" ("PK_user") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyroommembers_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions" ("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyroommembers_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits" ("PK_unit") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbchatmessages" (
    "PK_chatMessage" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_room" INTEGER NOT NULL,
    "FK_citizen" INTEGER,
    "FK_user" INTEGER,
    "FK_institution" INTEGER,
    "FK_unit" INTEGER,
    "senderRole" TEXT NOT NULL,
    "senderName" TEXT NOT NULL,
    "messageType" TEXT NOT NULL,
    "message" TEXT,
    "fileUrl" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbchatmessages_FK_room_fkey" FOREIGN KEY ("FK_room") REFERENCES "tbemergencyrooms" ("PK_room") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbchatmessages_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens" ("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbchatmessages_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers" ("PK_user") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbchatmessages_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions" ("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbchatmessages_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits" ("PK_unit") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbunitlocations" (
    "PK_unitLocation" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_unit" INTEGER NOT NULL,
    "latitude" REAL NOT NULL,
    "longitude" REAL NOT NULL,
    "speed" REAL,
    "heading" REAL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbunitlocations_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits" ("PK_unit") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbevidences" (
    "PK_evidence" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "FK_citizen" INTEGER,
    "FK_user" INTEGER,
    "fileType" TEXT NOT NULL,
    "fileUrl" TEXT NOT NULL,
    "description" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbevidences_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbevidences_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens" ("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbevidences_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers" ("PK_user") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbaianalyses" (
    "PK_aiAnalysis" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "confidenceScore" REAL NOT NULL,
    "suggestedPriority" TEXT NOT NULL,
    "extractedEntities" JSONB NOT NULL,
    "rawResponse" JSONB,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbaianalyses_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencyrequirements" (
    "PK_requirement" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "FK_resourceType" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "status" TEXT NOT NULL DEFAULT 'PENDIENTE',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbemergencyrequirements_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyrequirements_FK_resourceType_fkey" FOREIGN KEY ("FK_resourceType") REFERENCES "tbresourcetypes" ("PK_resourceType") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencyassignments" (
    "PK_assignment" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "FK_institution" INTEGER NOT NULL,
    "FK_subinstitution" INTEGER,
    "FK_unit" INTEGER,
    "status" TEXT NOT NULL,
    "assignedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "acceptedAt" DATETIME,
    "arrivedAt" DATETIME,
    "completedAt" DATETIME,
    CONSTRAINT "tbemergencyassignments_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyassignments_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions" ("PK_institution") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyassignments_FK_subinstitution_fkey" FOREIGN KEY ("FK_subinstitution") REFERENCES "tbsubinstitutions" ("PK_subinstitution") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyassignments_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits" ("PK_unit") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbassignmenttracking" (
    "PK_tracking" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_assignment" INTEGER NOT NULL,
    "FK_unit" INTEGER NOT NULL,
    "latitude" REAL NOT NULL,
    "longitude" REAL NOT NULL,
    "speed" REAL,
    "heading" REAL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbassignmenttracking_FK_assignment_fkey" FOREIGN KEY ("FK_assignment") REFERENCES "tbemergencyassignments" ("PK_assignment") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbassignmenttracking_FK_unit_fkey" FOREIGN KEY ("FK_unit") REFERENCES "tbunits" ("PK_unit") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencystatushistory" (
    "PK_statusHistory" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "FK_user" INTEGER,
    "previousStatus" TEXT,
    "newStatus" TEXT NOT NULL,
    "changeReason" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbemergencystatushistory_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbemergencystatushistory_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers" ("PK_user") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencyprogressreports" (
    "PK_progressReport" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "FK_institution" INTEGER,
    "FK_user" INTEGER,
    "reportText" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbemergencyprogressreports_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyprogressreports_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions" ("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbemergencyprogressreports_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers" ("PK_user") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbnotifications" (
    "PK_notification" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_citizen" INTEGER,
    "FK_user" INTEGER,
    "FK_emergency" INTEGER,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "notificationType" TEXT NOT NULL,
    "isRead" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbnotifications_FK_citizen_fkey" FOREIGN KEY ("FK_citizen") REFERENCES "tbcitizens" ("PK_citizen") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbnotifications_FK_user_fkey" FOREIGN KEY ("FK_user") REFERENCES "tbusers" ("PK_user") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "tbnotifications_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "tbemergencydestinations" (
    "PK_destination" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "FK_emergency" INTEGER NOT NULL,
    "FK_institution" INTEGER,
    "destinationName" TEXT NOT NULL,
    "latitude" REAL,
    "longitude" REAL,
    "arrivalEta" DATETIME,
    "arrivedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "tbemergencydestinations_FK_emergency_fkey" FOREIGN KEY ("FK_emergency") REFERENCES "tbemergencies" ("PK_emergency") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "tbemergencydestinations_FK_institution_fkey" FOREIGN KEY ("FK_institution") REFERENCES "tbinstitutions" ("PK_institution") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "tbprivileges_privilege_key" ON "tbprivileges"("privilege");

-- CreateIndex
CREATE UNIQUE INDEX "tbprivileges_privilegeCode_key" ON "tbprivileges"("privilegeCode");

-- CreateIndex
CREATE UNIQUE INDEX "tbcitizens_CI_key" ON "tbcitizens"("CI");

-- CreateIndex
CREATE UNIQUE INDEX "tbcitizens_phoneNumber_key" ON "tbcitizens"("phoneNumber");

-- CreateIndex
CREATE UNIQUE INDEX "tbcitizens_email_key" ON "tbcitizens"("email");

-- CreateIndex
CREATE UNIQUE INDEX "tbinstitutiontypes_code_key" ON "tbinstitutiontypes"("code");

-- CreateIndex
CREATE INDEX "tbinstitutions_FK_institutionType_idx" ON "tbinstitutions"("FK_institutionType");

-- CreateIndex
CREATE INDEX "tbsubinstitutions_FK_institution_idx" ON "tbsubinstitutions"("FK_institution");

-- CreateIndex
CREATE UNIQUE INDEX "tbusers_email_key" ON "tbusers"("email");

-- CreateIndex
CREATE INDEX "tbusers_FK_privilege_idx" ON "tbusers"("FK_privilege");

-- CreateIndex
CREATE INDEX "tbusers_FK_institution_idx" ON "tbusers"("FK_institution");

-- CreateIndex
CREATE INDEX "tbusers_FK_subinstitution_idx" ON "tbusers"("FK_subinstitution");

-- CreateIndex
CREATE UNIQUE INDEX "tbdevices_FK_citizen_key" ON "tbdevices"("FK_citizen");

-- CreateIndex
CREATE UNIQUE INDEX "tbusersdevices_FK_user_key" ON "tbusersdevices"("FK_user");

-- CreateIndex
CREATE UNIQUE INDEX "tbresourcetypes_code_key" ON "tbresourcetypes"("code");

-- CreateIndex
CREATE INDEX "tbinstitutionservices_FK_institution_idx" ON "tbinstitutionservices"("FK_institution");

-- CreateIndex
CREATE INDEX "tbinstitutionservices_FK_resourceType_idx" ON "tbinstitutionservices"("FK_resourceType");

-- CreateIndex
CREATE UNIQUE INDEX "tbinstitutionservices_FK_institution_FK_resourceType_key" ON "tbinstitutionservices"("FK_institution", "FK_resourceType");

-- CreateIndex
CREATE UNIQUE INDEX "tbunits_unitCode_key" ON "tbunits"("unitCode");

-- CreateIndex
CREATE INDEX "tbunits_FK_institution_idx" ON "tbunits"("FK_institution");

-- CreateIndex
CREATE INDEX "tbunits_FK_resourceType_idx" ON "tbunits"("FK_resourceType");

-- CreateIndex
CREATE INDEX "tbunits_isAvailable_isActive_idx" ON "tbunits"("isAvailable", "isActive");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencytypes_code_key" ON "tbemergencytypes"("code");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencies_emergencyCode_key" ON "tbemergencies"("emergencyCode");

-- CreateIndex
CREATE INDEX "tbemergencies_FK_citizen_idx" ON "tbemergencies"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbemergencies_FK_emergencyType_idx" ON "tbemergencies"("FK_emergencyType");

-- CreateIndex
CREATE INDEX "tbemergencies_FK_parentEmergency_idx" ON "tbemergencies"("FK_parentEmergency");

-- CreateIndex
CREATE INDEX "tbemergencies_status_idx" ON "tbemergencies"("status");

-- CreateIndex
CREATE INDEX "tbemergencies_priority_idx" ON "tbemergencies"("priority");

-- CreateIndex
CREATE INDEX "tbemergencies_reportedAt_idx" ON "tbemergencies"("reportedAt");

-- CreateIndex
CREATE INDEX "tbaisessions_FK_citizen_idx" ON "tbaisessions"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbaisessions_FK_emergency_idx" ON "tbaisessions"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyreports_FK_emergency_idx" ON "tbemergencyreports"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyreports_FK_citizen_idx" ON "tbemergencyreports"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbemergencyreports_isLinkedByAI_idx" ON "tbemergencyreports"("isLinkedByAI");

-- CreateIndex
CREATE INDEX "tbemergencylocations_FK_emergency_idx" ON "tbemergencylocations"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbcalls_FK_emergency_idx" ON "tbcalls"("FK_emergency");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencyrooms_FK_emergency_key" ON "tbemergencyrooms"("FK_emergency");

-- CreateIndex
CREATE UNIQUE INDEX "tbemergencyrooms_roomCode_key" ON "tbemergencyrooms"("roomCode");

-- CreateIndex
CREATE INDEX "tbemergencyroommembers_FK_room_idx" ON "tbemergencyroommembers"("FK_room");

-- CreateIndex
CREATE INDEX "tbemergencyroommembers_FK_citizen_idx" ON "tbemergencyroommembers"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbemergencyroommembers_FK_institution_idx" ON "tbemergencyroommembers"("FK_institution");

-- CreateIndex
CREATE INDEX "tbemergencyroommembers_FK_unit_idx" ON "tbemergencyroommembers"("FK_unit");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_room_idx" ON "tbchatmessages"("FK_room");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_citizen_idx" ON "tbchatmessages"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_user_idx" ON "tbchatmessages"("FK_user");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_institution_idx" ON "tbchatmessages"("FK_institution");

-- CreateIndex
CREATE INDEX "tbchatmessages_FK_unit_idx" ON "tbchatmessages"("FK_unit");

-- CreateIndex
CREATE INDEX "tbunitlocations_FK_unit_idx" ON "tbunitlocations"("FK_unit");

-- CreateIndex
CREATE INDEX "tbunitlocations_createdAt_idx" ON "tbunitlocations"("createdAt");

-- CreateIndex
CREATE INDEX "tbevidences_FK_emergency_idx" ON "tbevidences"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbevidences_FK_citizen_idx" ON "tbevidences"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbevidences_FK_user_idx" ON "tbevidences"("FK_user");

-- CreateIndex
CREATE INDEX "tbaianalyses_FK_emergency_idx" ON "tbaianalyses"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyrequirements_FK_emergency_idx" ON "tbemergencyrequirements"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyrequirements_FK_resourceType_idx" ON "tbemergencyrequirements"("FK_resourceType");

-- CreateIndex
CREATE INDEX "tbemergencyassignments_FK_emergency_idx" ON "tbemergencyassignments"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyassignments_FK_institution_idx" ON "tbemergencyassignments"("FK_institution");

-- CreateIndex
CREATE INDEX "tbemergencyassignments_FK_subinstitution_idx" ON "tbemergencyassignments"("FK_subinstitution");

-- CreateIndex
CREATE INDEX "tbemergencyassignments_FK_unit_idx" ON "tbemergencyassignments"("FK_unit");

-- CreateIndex
CREATE INDEX "tbassignmenttracking_FK_assignment_idx" ON "tbassignmenttracking"("FK_assignment");

-- CreateIndex
CREATE INDEX "tbassignmenttracking_FK_unit_idx" ON "tbassignmenttracking"("FK_unit");

-- CreateIndex
CREATE INDEX "tbassignmenttracking_createdAt_idx" ON "tbassignmenttracking"("createdAt");

-- CreateIndex
CREATE INDEX "tbemergencystatushistory_FK_emergency_idx" ON "tbemergencystatushistory"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencystatushistory_FK_user_idx" ON "tbemergencystatushistory"("FK_user");

-- CreateIndex
CREATE INDEX "tbemergencyprogressreports_FK_emergency_idx" ON "tbemergencyprogressreports"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencyprogressreports_FK_institution_idx" ON "tbemergencyprogressreports"("FK_institution");

-- CreateIndex
CREATE INDEX "tbemergencyprogressreports_FK_user_idx" ON "tbemergencyprogressreports"("FK_user");

-- CreateIndex
CREATE INDEX "tbnotifications_FK_citizen_idx" ON "tbnotifications"("FK_citizen");

-- CreateIndex
CREATE INDEX "tbnotifications_FK_user_idx" ON "tbnotifications"("FK_user");

-- CreateIndex
CREATE INDEX "tbnotifications_FK_emergency_idx" ON "tbnotifications"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencydestinations_FK_emergency_idx" ON "tbemergencydestinations"("FK_emergency");

-- CreateIndex
CREATE INDEX "tbemergencydestinations_FK_institution_idx" ON "tbemergencydestinations"("FK_institution");
