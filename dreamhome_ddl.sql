-- =====================================================
-- DreamHome - Physical Model (PostgreSQL)
-- Sumber: Figure 16.9 Global relation diagram
-- =====================================================

DROP SCHEMA IF EXISTS dreamhome CASCADE;
CREATE SCHEMA dreamhome;
SET search_path TO dreamhome;

-- ---------- Branch (FK ke Manager ditambah belakangan) ----------
CREATE TABLE branch (
    branch_no      VARCHAR(4)   PRIMARY KEY,
    street         VARCHAR(50),
    city           VARCHAR(30),
    postcode       VARCHAR(10),
    mgr_staff_no   VARCHAR(5)   UNIQUE            -- 1..1 Manages
);

-- ---------- Telephone ----------
CREATE TABLE telephone (
    tel_no     VARCHAR(15) PRIMARY KEY,
    branch_no  VARCHAR(4)  NOT NULL,
    CONSTRAINT fk_tel_branch FOREIGN KEY (branch_no)
        REFERENCES branch (branch_no) ON UPDATE CASCADE ON DELETE CASCADE
);

-- ---------- Staff ----------
CREATE TABLE staff (
    staff_no             VARCHAR(5)   PRIMARY KEY,
    f_name               VARCHAR(30),
    l_name               VARCHAR(30),
    position             VARCHAR(20),
    sex                  CHAR(1) CHECK (sex IN ('M','F')),
    dob                  DATE,
    salary               NUMERIC(10,2) CHECK (salary >= 0),
    supervisor_staff_no  VARCHAR(5),
    branch_no            VARCHAR(4)   NOT NULL,
    CONSTRAINT fk_staff_supervisor FOREIGN KEY (supervisor_staff_no)
        REFERENCES staff (staff_no) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_staff_branch FOREIGN KEY (branch_no)
        REFERENCES branch (branch_no) ON UPDATE CASCADE
);

-- ---------- Manager (IS-A Staff) ----------
CREATE TABLE manager (
    staff_no  VARCHAR(5) PRIMARY KEY,
    CONSTRAINT fk_manager_staff FOREIGN KEY (staff_no)
        REFERENCES staff (staff_no) ON UPDATE CASCADE ON DELETE CASCADE
);

-- FK Branch -> Manager (ditunda karena circular dependency)
ALTER TABLE branch
    ADD CONSTRAINT fk_branch_manager FOREIGN KEY (mgr_staff_no)
        REFERENCES manager (staff_no) ON UPDATE CASCADE ON DELETE SET NULL;

-- ---------- Client ----------
CREATE TABLE client (
    client_no  VARCHAR(5) PRIMARY KEY,
    f_name     VARCHAR(30),
    l_name     VARCHAR(30),
    tel_no     VARCHAR(15),
    pref_type  VARCHAR(10),
    max_rent   NUMERIC(10,2)
);

-- ---------- Registration ----------
CREATE TABLE registration (
    client_no  VARCHAR(5)  PRIMARY KEY,
    branch_no  VARCHAR(4)  NOT NULL,
    staff_no   VARCHAR(5)  NOT NULL,
    date_joined DATE,
    CONSTRAINT fk_reg_client FOREIGN KEY (client_no)
        REFERENCES client (client_no) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_reg_branch FOREIGN KEY (branch_no)
        REFERENCES branch (branch_no) ON UPDATE CASCADE,
    CONSTRAINT fk_reg_staff FOREIGN KEY (staff_no)
        REFERENCES staff (staff_no) ON UPDATE CASCADE
);

-- ---------- Owner (supertype), PrivateOwner, BusinessOwner ----------
CREATE TABLE owner (
    owner_no  VARCHAR(5) PRIMARY KEY
);

CREATE TABLE private_owner (
    owner_no  VARCHAR(5) PRIMARY KEY,
    f_name    VARCHAR(30),
    l_name    VARCHAR(30),
    address   VARCHAR(100),
    tel_no    VARCHAR(15),
    CONSTRAINT fk_powner_owner FOREIGN KEY (owner_no)
        REFERENCES owner (owner_no) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE business_owner (
    owner_no   VARCHAR(5) PRIMARY KEY,
    b_name     VARCHAR(50),
    b_type     VARCHAR(30),
    address    VARCHAR(100),
    tel_no     VARCHAR(15),
    contact_name VARCHAR(50),
    CONSTRAINT fk_bowner_owner FOREIGN KEY (owner_no)
        REFERENCES owner (owner_no) ON UPDATE CASCADE ON DELETE CASCADE
);

-- ---------- PropertyForRent ----------
CREATE TABLE property_for_rent (
    property_no  VARCHAR(5) PRIMARY KEY,
    street       VARCHAR(50),
    city         VARCHAR(30),
    postcode     VARCHAR(10),
    type         VARCHAR(10),
    rooms        SMALLINT,
    rent         NUMERIC(10,2),
    owner_no     VARCHAR(5) NOT NULL,
    staff_no     VARCHAR(5),
    branch_no    VARCHAR(4) NOT NULL,
    CONSTRAINT fk_prop_owner FOREIGN KEY (owner_no)
        REFERENCES owner (owner_no) ON UPDATE CASCADE,
    CONSTRAINT fk_prop_staff FOREIGN KEY (staff_no)
        REFERENCES staff (staff_no) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_prop_branch FOREIGN KEY (branch_no)
        REFERENCES branch (branch_no) ON UPDATE CASCADE
);

-- ---------- Lease ----------
CREATE TABLE lease (
    lease_no     VARCHAR(8) PRIMARY KEY,
    client_no    VARCHAR(5) NOT NULL,
    property_no  VARCHAR(5) NOT NULL,
    rent_start   DATE,
    rent_finish  DATE,
    CONSTRAINT fk_lease_client FOREIGN KEY (client_no)
        REFERENCES client (client_no) ON UPDATE CASCADE,
    CONSTRAINT fk_lease_property FOREIGN KEY (property_no)
        REFERENCES property_for_rent (property_no) ON UPDATE CASCADE,
    CONSTRAINT ck_lease_dates CHECK (rent_finish IS NULL OR rent_finish >= rent_start)
);

-- ---------- Viewing (PK komposit) ----------
CREATE TABLE viewing (
    client_no    VARCHAR(5) NOT NULL,
    property_no  VARCHAR(5) NOT NULL,
    view_date    DATE,
    comment      VARCHAR(200),
    PRIMARY KEY (client_no, property_no),
    CONSTRAINT fk_view_client FOREIGN KEY (client_no)
        REFERENCES client (client_no) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_view_property FOREIGN KEY (property_no)
        REFERENCES property_for_rent (property_no) ON UPDATE CASCADE ON DELETE CASCADE
);

-- ---------- Newspaper ----------
CREATE TABLE newspaper (
    newspaper_name  VARCHAR(50) PRIMARY KEY,
    address         VARCHAR(100),
    tel_no          VARCHAR(15),
    contact_name    VARCHAR(50)
);

-- ---------- Advert (PK komposit 3 kolom) ----------
CREATE TABLE advert (
    property_no     VARCHAR(5)  NOT NULL,
    newspaper_name  VARCHAR(50) NOT NULL,
    date_advert     DATE        NOT NULL,
    cost            NUMERIC(10,2),
    PRIMARY KEY (property_no, newspaper_name, date_advert),
    CONSTRAINT fk_advert_property FOREIGN KEY (property_no)
        REFERENCES property_for_rent (property_no) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_advert_newspaper FOREIGN KEY (newspaper_name)
        REFERENCES newspaper (newspaper_name) ON UPDATE CASCADE
);

-- ---------- Index untuk FK ----------
CREATE INDEX idx_staff_branch     ON staff (branch_no);
CREATE INDEX idx_staff_supervisor ON staff (supervisor_staff_no);
CREATE INDEX idx_prop_owner       ON property_for_rent (owner_no);
CREATE INDEX idx_prop_staff       ON property_for_rent (staff_no);
CREATE INDEX idx_prop_branch      ON property_for_rent (branch_no);
CREATE INDEX idx_lease_client     ON lease (client_no);
CREATE INDEX idx_lease_property   ON lease (property_no);
CREATE INDEX idx_reg_branch       ON registration (branch_no);
CREATE INDEX idx_reg_staff        ON registration (staff_no);
