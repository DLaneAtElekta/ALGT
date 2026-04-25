-- Treatment Management System - Initial Schema
-- Target: PostgreSQL 12+
-- Style: 3NF normalized relational schema for a 1990s-era fat-client app.
--
-- Conventions:
--   * Surrogate integer PKs (sequence-backed) named <Table>ID
--   * Natural keys enforced via UNIQUE constraints
--   * RowVersion column for optimistic concurrency (incremented by trigger)
--   * Audit columns: CreatedAt, CreatedBy, UpdatedAt, UpdatedBy
--   * All identifiers PascalCase, quoted to preserve case (period-correct for
--     a Delphi/Lazarus shop that thinks in terms of object names, not snake_case)

BEGIN;

CREATE SCHEMA IF NOT EXISTS tm;
SET search_path TO tm, public;

-- ---------------------------------------------------------------------------
-- RowVersion trigger: bumps RowVersion on every UPDATE for optimistic locking
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION tm.bump_rowversion() RETURNS trigger AS $$
BEGIN
    NEW."RowVersion" := OLD."RowVersion" + 1;
    NEW."UpdatedAt"  := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------------
-- Patients
-- ---------------------------------------------------------------------------
CREATE TABLE tm."Patients" (
    "PatientID"     SERIAL PRIMARY KEY,
    "MRN"           VARCHAR(20)  NOT NULL UNIQUE,
    "LastName"      VARCHAR(60)  NOT NULL,
    "FirstName"     VARCHAR(60)  NOT NULL,
    "MiddleName"    VARCHAR(60),
    "DateOfBirth"   DATE         NOT NULL,
    "Sex"           CHAR(1)      NOT NULL CHECK ("Sex" IN ('M','F','O','U')),
    "AddressLine1"  VARCHAR(80),
    "AddressLine2"  VARCHAR(80),
    "City"          VARCHAR(60),
    "StateProv"     VARCHAR(40),
    "PostalCode"    VARCHAR(20),
    "Country"       VARCHAR(40)  DEFAULT 'USA',
    "PhoneHome"     VARCHAR(30),
    "PhoneMobile"   VARCHAR(30),
    "Email"         VARCHAR(120),
    "Notes"         TEXT,
    "Active"        BOOLEAN      NOT NULL DEFAULT TRUE,
    "RowVersion"    INTEGER      NOT NULL DEFAULT 1,
    "CreatedAt"     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "CreatedBy"     VARCHAR(60)  NOT NULL DEFAULT CURRENT_USER,
    "UpdatedAt"     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedBy"     VARCHAR(60)  NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT "CK_Patients_DOB"  CHECK ("DateOfBirth" <= CURRENT_DATE)
);
CREATE INDEX "IX_Patients_LastName"  ON tm."Patients" ("LastName", "FirstName");
CREATE INDEX "IX_Patients_DOB"       ON tm."Patients" ("DateOfBirth");
CREATE TRIGGER "TR_Patients_RowVersion"
    BEFORE UPDATE ON tm."Patients"
    FOR EACH ROW EXECUTE FUNCTION tm.bump_rowversion();

-- ---------------------------------------------------------------------------
-- TreatmentPlans
-- ---------------------------------------------------------------------------
CREATE TABLE tm."TreatmentPlans" (
    "PlanID"            SERIAL PRIMARY KEY,
    "PatientID"         INTEGER      NOT NULL REFERENCES tm."Patients"("PatientID"),
    "PlanCode"          VARCHAR(20)  NOT NULL,
    "PlanName"          VARCHAR(120) NOT NULL,
    "Diagnosis"         VARCHAR(200),
    "TreatmentSite"     VARCHAR(80),
    "PrescribedDose"    NUMERIC(8,2),                  -- cGy
    "Fractions"         INTEGER      CHECK ("Fractions" IS NULL OR "Fractions" > 0),
    "DosePerFraction"   NUMERIC(8,2),                  -- cGy
    "PlanStatus"        VARCHAR(20)  NOT NULL DEFAULT 'Draft'
                        CHECK ("PlanStatus" IN ('Draft','UnderReview','Approved','Active','Completed','Cancelled')),
    "ApprovedBy"        VARCHAR(60),
    "ApprovedAt"        TIMESTAMP,
    "Notes"             TEXT,
    "RowVersion"        INTEGER      NOT NULL DEFAULT 1,
    "CreatedAt"         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "CreatedBy"         VARCHAR(60)  NOT NULL DEFAULT CURRENT_USER,
    "UpdatedAt"         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedBy"         VARCHAR(60)  NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT "UQ_Plans_Patient_Code" UNIQUE ("PatientID", "PlanCode"),
    CONSTRAINT "CK_Plans_Approval"
        CHECK (("PlanStatus" IN ('Approved','Active','Completed'))
                = ("ApprovedBy" IS NOT NULL AND "ApprovedAt" IS NOT NULL))
);
CREATE INDEX "IX_Plans_Patient" ON tm."TreatmentPlans" ("PatientID");
CREATE INDEX "IX_Plans_Status"  ON tm."TreatmentPlans" ("PlanStatus");
CREATE TRIGGER "TR_Plans_RowVersion"
    BEFORE UPDATE ON tm."TreatmentPlans"
    FOR EACH ROW EXECUTE FUNCTION tm.bump_rowversion();

-- ---------------------------------------------------------------------------
-- Appointments
-- ---------------------------------------------------------------------------
CREATE TABLE tm."Appointments" (
    "AppointmentID"     SERIAL PRIMARY KEY,
    "PatientID"         INTEGER      NOT NULL REFERENCES tm."Patients"("PatientID"),
    "PlanID"            INTEGER      REFERENCES tm."TreatmentPlans"("PlanID"),
    "ScheduledStart"    TIMESTAMP    NOT NULL,
    "ScheduledEnd"      TIMESTAMP    NOT NULL,
    "AppointmentType"   VARCHAR(30)  NOT NULL DEFAULT 'Treatment'
                        CHECK ("AppointmentType" IN ('Consult','Simulation','Treatment','FollowUp','Other')),
    "Status"            VARCHAR(20)  NOT NULL DEFAULT 'Scheduled'
                        CHECK ("Status" IN ('Scheduled','CheckedIn','InProgress','Completed','Cancelled','NoShow')),
    "Resource"          VARCHAR(60),                   -- machine / room
    "CheckedInAt"       TIMESTAMP,
    "CompletedAt"       TIMESTAMP,
    "CancelReason"      VARCHAR(200),
    "Notes"             TEXT,
    "RowVersion"        INTEGER      NOT NULL DEFAULT 1,
    "CreatedAt"         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "CreatedBy"         VARCHAR(60)  NOT NULL DEFAULT CURRENT_USER,
    "UpdatedAt"         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedBy"         VARCHAR(60)  NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT "CK_Appt_Range"   CHECK ("ScheduledEnd" > "ScheduledStart")
);
CREATE INDEX "IX_Appt_Patient"   ON tm."Appointments" ("PatientID");
CREATE INDEX "IX_Appt_Plan"      ON tm."Appointments" ("PlanID");
CREATE INDEX "IX_Appt_Schedule"  ON tm."Appointments" ("ScheduledStart");
CREATE INDEX "IX_Appt_Status"    ON tm."Appointments" ("Status");
CREATE TRIGGER "TR_Appt_RowVersion"
    BEFORE UPDATE ON tm."Appointments"
    FOR EACH ROW EXECUTE FUNCTION tm.bump_rowversion();

-- ---------------------------------------------------------------------------
-- TreatmentSessions
-- One session per fraction delivered. Linked to an Appointment.
-- ---------------------------------------------------------------------------
CREATE TABLE tm."TreatmentSessions" (
    "SessionID"         SERIAL PRIMARY KEY,
    "AppointmentID"     INTEGER      NOT NULL UNIQUE REFERENCES tm."Appointments"("AppointmentID"),
    "PlanID"            INTEGER      NOT NULL REFERENCES tm."TreatmentPlans"("PlanID"),
    "FractionNumber"    INTEGER      NOT NULL CHECK ("FractionNumber" > 0),
    "DeliveredDose"     NUMERIC(8,2),                  -- cGy actually delivered
    "OffsetAnterior"    NUMERIC(6,1),                  -- mm; matches treatment-offset/
    "OffsetSuperior"    NUMERIC(6,1),
    "OffsetLateral"     NUMERIC(6,1),
    "OffsetMagnitude"   NUMERIC(8,2),                  -- ISqrt-derived; mm
    "StartedAt"         TIMESTAMP,
    "EndedAt"           TIMESTAMP,
    "Status"            VARCHAR(20)  NOT NULL DEFAULT 'Pending'
                        CHECK ("Status" IN ('Pending','InProgress','Completed','Aborted')),
    "Therapist"         VARCHAR(60),
    "Notes"             TEXT,
    "RowVersion"        INTEGER      NOT NULL DEFAULT 1,
    "CreatedAt"         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "CreatedBy"         VARCHAR(60)  NOT NULL DEFAULT CURRENT_USER,
    "UpdatedAt"         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedBy"         VARCHAR(60)  NOT NULL DEFAULT CURRENT_USER,
    CONSTRAINT "UQ_Session_Plan_Fraction" UNIQUE ("PlanID", "FractionNumber"),
    CONSTRAINT "CK_Session_TimeRange"
        CHECK ("EndedAt" IS NULL OR "StartedAt" IS NULL OR "EndedAt" >= "StartedAt")
);
CREATE INDEX "IX_Session_Plan"   ON tm."TreatmentSessions" ("PlanID");
CREATE INDEX "IX_Session_Status" ON tm."TreatmentSessions" ("Status");
CREATE TRIGGER "TR_Session_RowVersion"
    BEFORE UPDATE ON tm."TreatmentSessions"
    FOR EACH ROW EXECUTE FUNCTION tm.bump_rowversion();

COMMIT;
