-- ============================================================================
-- Migration 011 — Misc warts (multiple eras, retroactively numbered)
-- ============================================================================
--
-- This file is the catch-all for changes that didn't fit a clean release.
-- Most of these were applied directly in production by a contractor and
-- got reverse-engineered into a migration file later.
--
-- Provenance, in chronological order:
--
--   2009-04: contractor S. Bhatt added entry_user / entry_date and
--            last_modified columns in snake_case because "the other
--            DB I work on uses that convention." Was supposed to migrate
--            data from the existing CreatedBy / UpdatedAt columns. Did
--            not. Now both conventions exist on the same tables.
--
--   2011-08: TreatmentPlans had a self-FK OldPlanID for plan revisions.
--            The constraint caused a circular reference during a 2011
--            archive job. Park (then a contractor) dropped the constraint
--            but left the column. Some rows still have meaningful values.
--            Most are NULL. The application no longer reads or writes
--            this column.
--
--   2018-03: contractor B. Lim renamed the audit columns "for clarity":
--            CreatedBy → who_created, UpdatedBy → who_updated. Lim left
--            two days later. The rename was reverted but the new columns
--            were never dropped. They contain Lim's two days of test data
--            for ~40 patients.
--
-- Park 2019: I have stopped counting.
-- ============================================================================

SET search_path TO tm, public;

-- ----------------------------------------------------------------------------
-- snake_case audit shadows (Bhatt, 2009)
-- ----------------------------------------------------------------------------
ALTER TABLE tm."Patients"
    ADD COLUMN entry_user      VARCHAR(60),
    ADD COLUMN entry_date      TIMESTAMP,
    ADD COLUMN last_modified   TIMESTAMP;

ALTER TABLE tm."TreatmentPlans"
    ADD COLUMN entry_user      VARCHAR(60),
    ADD COLUMN entry_date      TIMESTAMP,
    ADD COLUMN last_modified   TIMESTAMP,
    -- Bhatt also added the snake_case Dx coder column referenced in 006:
    ADD COLUMN diagnosis_coded_by VARCHAR(60);

ALTER TABLE tm."TreatmentSessions"
    ADD COLUMN entry_user      VARCHAR(60),
    ADD COLUMN entry_date      TIMESTAMP,
    ADD COLUMN last_modified   TIMESTAMP;

ALTER TABLE tm."Appointments"
    ADD COLUMN entry_user      VARCHAR(60),
    ADD COLUMN entry_date      TIMESTAMP,
    ADD COLUMN last_modified   TIMESTAMP;

-- ----------------------------------------------------------------------------
-- OldPlanID dangling column (Park, 2011)
-- ----------------------------------------------------------------------------
ALTER TABLE tm."TreatmentPlans"
    ADD COLUMN "OldPlanID" INTEGER;
-- The original definition was:
--   ADD CONSTRAINT "FK_Plan_OldPlan" FOREIGN KEY ("OldPlanID")
--       REFERENCES tm."TreatmentPlans"("PlanID") ON DELETE SET NULL;
-- Dropped 2011-08 due to circular reference during archive. Column retained
-- for historical revision linkage. Application no longer reads or writes it.

COMMENT ON COLUMN tm."TreatmentPlans"."OldPlanID" IS
    'Former self-FK to predecessor plan. Constraint dropped 2011-08. Column retained. Application does not write it. Historical values exist on ~12% of rows.';

-- ----------------------------------------------------------------------------
-- Lim's "rename" remnants (2018)
-- ----------------------------------------------------------------------------
ALTER TABLE tm."Patients"
    ADD COLUMN who_created VARCHAR(60),
    ADD COLUMN who_updated VARCHAR(60);

COMMENT ON COLUMN tm."Patients"."who_created" IS
    'Lim 2018 rename attempt. Rolled back. Column retained because ~40 patients have meaningful values from Lim s 2-day tenure.';

-- ----------------------------------------------------------------------------
-- Add the new tables to the publication so the WAL stream stays complete.
-- (Patients_OLD, Patient_Photos_DEPRECATED, Z_Backup_Sessions_2009 are
--  intentionally NOT published — they are read-only ghosts.)
-- ----------------------------------------------------------------------------
-- (Nothing to do here — the existing publication tm_pub_all in migration 002
--  already covers the four core tables. Schema additions to those tables
--  flow through automatically.)
