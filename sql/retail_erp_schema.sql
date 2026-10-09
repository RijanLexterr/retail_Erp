-- Retail Management System / Lightweight Retail ERP (with Granular RBAC)
-- MySQL 8.0+
-- Scope: purchasing, inventory, quotations, sales, receivables/payables,
-- payment verification, item release, delivery scheduling, expenses, and reports.
--
-- Important:
-- 1) This is an operational schema, not a full double-entry accounting ledger.
-- 2) Use DECIMAL for all money; never FLOAT/DOUBLE.
-- 3) Keep posted transactions immutable where practical; use void/reversal records.
-- 4) Store password hashes only (e.g. Argon2id/bcrypt), never plaintext passwords.

CREATE DATABASE IF NOT EXISTS retail_erp
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE retail_erp;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS calendar_events;
DROP TABLE IF EXISTS delivery_items;
DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS stock_movements;
DROP TABLE IF EXISTS item_releases;
DROP TABLE IF EXISTS expense_attachments;
DROP TABLE IF EXISTS expenses;
DROP TABLE IF EXISTS supplier_payment_allocations;
DROP TABLE IF EXISTS supplier_payments;
DROP TABLE IF EXISTS supplier_bills;
DROP TABLE IF EXISTS supplier_bill_items;
DROP TABLE IF EXISTS customer_payment_allocations;
DROP TABLE IF EXISTS customer_payments;
DROP TABLE IF EXISTS sales_invoices;
DROP TABLE IF EXISTS sales_invoice_items;
DROP TABLE IF EXISTS sales_order_items;
DROP TABLE IF EXISTS sales_orders;
DROP TABLE IF EXISTS quotation_items;
DROP TABLE IF EXISTS quotations;
DROP TABLE IF EXISTS goods_receipt_items;
DROP TABLE IF EXISTS goods_receipts;
DROP TABLE IF EXISTS purchase_order_items;
DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS inventory_balances;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_categories;
DROP TABLE IF EXISTS units_of_measure;
DROP TABLE IF EXISTS warehouses;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS company_settings;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE company_settings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  company_name VARCHAR(180) NOT NULL,
  business_address VARCHAR(255) NULL,
  tin VARCHAR(40) NULL,
  phone VARCHAR(40) NULL,
  email VARCHAR(160) NULL,
  currency_code CHAR(3) NOT NULL DEFAULT 'PHP',
  timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Manila',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE roles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(60) NOT NULL UNIQUE,
  description VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Granular Permissions table for fine-grained access control
CREATE TABLE permissions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  permission_code VARCHAR(100) NOT NULL UNIQUE, -- e.g., 'invoices.delete', 'reports.view'
  description VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Linking roles to granular permissions
CREATE TABLE role_permissions (
  role_id BIGINT UNSIGNED NOT NULL,
  permission_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (role_id, permission_id),
  CONSTRAINT fk_rp_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  CONSTRAINT fk_rp_permission FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(160) NOT NULL,
  username VARCHAR(80) NOT NULL UNIQUE,
  email VARCHAR(160) NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  status ENUM('active','disabled') NOT NULL DEFAULT 'active',
  last_login_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE user_roles (
  user_id BIGINT UNSIGNED NOT NULL,
  role_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE customers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_code VARCHAR(40) NOT NULL UNIQUE,
  customer_name VARCHAR(180) NOT NULL,
  contact_person VARCHAR(160) NULL,
  phone VARCHAR(40) NULL,
  email VARCHAR(160) NULL,
  billing_address VARCHAR(255) NULL,
  delivery_address VARCHAR(255) NULL,
  tin VARCHAR(40) NULL,
  credit_limit DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  payment_terms_days SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE suppliers (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  supplier_code VARCHAR(40) NOT NULL UNIQUE,
  supplier_name VARCHAR(180) NOT NULL,
  contact_person VARCHAR(160) NULL,
  phone VARCHAR(40) NULL,
  email VARCHAR(160) NULL,
  address VARCHAR(255) NULL,
  tin VARCHAR(40) NULL,
  payment_terms_days SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE warehouses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  warehouse_code VARCHAR(40) NOT NULL UNIQUE,
  warehouse_name VARCHAR(120) NOT NULL,
  address VARCHAR(255) NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE units_of_measure (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  unit_code VARCHAR(20) NOT NULL UNIQUE,
  unit_name VARCHAR(60) NOT NULL,
  decimal_places TINYINT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE product_categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(120) NOT NULL UNIQUE,
  description VARCHAR(255) NULL,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE products (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(80) NOT NULL UNIQUE,
  barcode VARCHAR(100) NULL UNIQUE,
  product_name VARCHAR(180) NOT NULL,
  description TEXT NULL,
  category_id BIGINT UNSIGNED NULL,
  unit_id BIGINT UNSIGNED NOT NULL,
  cost_price DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  selling_price DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  reorder_level DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  track_inventory TINYINT(1) NOT NULL DEFAULT 1,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_by BIGINT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES product_categories(id),
  CONSTRAINT fk_products_unit FOREIGN KEY (unit_id) REFERENCES units_of_measure(id),
  CONSTRAINT fk_products_creator FOREIGN KEY (created_by) REFERENCES users(id),
  INDEX idx_products_name (product_name),
  INDEX idx_products_category (category_id)
) ENGINE=InnoDB;

CREATE TABLE inventory_balances (
  product_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  quantity_on_hand DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  quantity_reserved DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id, warehouse_id),
  CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_inventory_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB;

CREATE TABLE purchase_orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  po_number VARCHAR(40) NOT NULL UNIQUE,
  supplier_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  order_date DATE NOT NULL,
  expected_date DATE NULL,
  status ENUM('draft','submitted','approved','partially_received','received','cancelled') NOT NULL DEFAULT 'draft',
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  approved_by BIGINT UNSIGNED NULL,
  approved_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
  CONSTRAINT fk_po_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_po_creator FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_po_approver FOREIGN KEY (approved_by) REFERENCES users(id),
  INDEX idx_po_supplier_date (supplier_id, order_date),
  INDEX idx_po_status (status)
) ENGINE=InnoDB;

CREATE TABLE purchase_order_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  description VARCHAR(255) NULL,
  quantity_ordered DECIMAL(14,4) NOT NULL,
  quantity_received DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  unit_cost DECIMAL(14,4) NOT NULL,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(14,2) NOT NULL,
  CONSTRAINT fk_poi_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
  CONSTRAINT fk_poi_product FOREIGN KEY (product_id) REFERENCES products(id),
  INDEX idx_poi_product (product_id)
) ENGINE=InnoDB;

CREATE TABLE goods_receipts (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  receipt_number VARCHAR(40) NOT NULL UNIQUE,
  purchase_order_id BIGINT UNSIGNED NOT NULL,
  received_date DATETIME NOT NULL,
  status ENUM('draft','posted','cancelled') NOT NULL DEFAULT 'draft',
  received_by BIGINT UNSIGNED NOT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_gr_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
  CONSTRAINT fk_gr_user FOREIGN KEY (received_by) REFERENCES users(id),
  INDEX idx_gr_date (received_date)
) ENGINE=InnoDB;

CREATE TABLE goods_receipt_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  goods_receipt_id BIGINT UNSIGNED NOT NULL,
  purchase_order_item_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  quantity_received DECIMAL(14,4) NOT NULL,
  unit_cost DECIMAL(14,4) NOT NULL,
  CONSTRAINT fk_gri_receipt FOREIGN KEY (goods_receipt_id) REFERENCES goods_receipts(id),
  CONSTRAINT fk_gri_po_item FOREIGN KEY (purchase_order_item_id) REFERENCES purchase_order_items(id),
  CONSTRAINT fk_gri_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

CREATE TABLE quotations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  quotation_number VARCHAR(40) NOT NULL UNIQUE,
  customer_id BIGINT UNSIGNED NOT NULL,
  quotation_date DATE NOT NULL,
  valid_until DATE NULL,
  status ENUM('draft','sent','accepted','rejected','expired','converted','cancelled') NOT NULL DEFAULT 'draft',
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_quote_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_quote_creator FOREIGN KEY (created_by) REFERENCES users(id),
  INDEX idx_quote_customer_date (customer_id, quotation_date),
  INDEX idx_quote_status (status)
) ENGINE=InnoDB;

CREATE TABLE quotation_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  quotation_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(14,4) NOT NULL,
  unit_price DECIMAL(14,4) NOT NULL,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(14,2) NOT NULL,
  CONSTRAINT fk_qi_quote FOREIGN KEY (quotation_id) REFERENCES quotations(id),
  CONSTRAINT fk_qi_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

CREATE TABLE sales_orders (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(40) NOT NULL UNIQUE,
  quotation_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  order_date DATE NOT NULL,
  requested_delivery_date DATE NULL,
  status ENUM('draft','confirmed','partially_released','released','completed','cancelled') NOT NULL DEFAULT 'draft',
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_so_quote FOREIGN KEY (quotation_id) REFERENCES quotations(id),
  CONSTRAINT fk_so_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_so_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_so_creator FOREIGN KEY (created_by) REFERENCES users(id),
  INDEX idx_so_customer_date (customer_id, order_date),
  INDEX idx_so_status (status)
) ENGINE=InnoDB;

CREATE TABLE sales_order_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sales_order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  description VARCHAR(255) NULL,
  quantity_ordered DECIMAL(14,4) NOT NULL,
  quantity_released DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  unit_price DECIMAL(14,4) NOT NULL,
  unit_cost_snapshot DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(14,2) NOT NULL,
  CONSTRAINT fk_soi_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_soi_product FOREIGN KEY (product_id) REFERENCES products(id),
  INDEX idx_soi_product (product_id)
) ENGINE=InnoDB;

CREATE TABLE sales_invoices (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  invoice_number VARCHAR(40) NOT NULL UNIQUE,
  sales_order_id BIGINT UNSIGNED NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  invoice_date DATE NOT NULL,
  due_date DATE NULL,
  status ENUM('draft','posted','partially_paid','paid','void') NOT NULL DEFAULT 'draft',
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  posted_by BIGINT UNSIGNED NULL,
  posted_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_invoice_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_invoice_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_invoice_creator FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_invoice_poster FOREIGN KEY (posted_by) REFERENCES users(id),
  INDEX idx_invoice_customer_due (customer_id, due_date),
  INDEX idx_invoice_date_status (invoice_date, status)
) ENGINE=InnoDB;

CREATE TABLE sales_invoice_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  invoice_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(14,4) NOT NULL,
  unit_price DECIMAL(14,4) NOT NULL,
  unit_cost_snapshot DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  discount_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  line_total DECIMAL(14,2) NOT NULL,
  CONSTRAINT fk_sii_invoice FOREIGN KEY (invoice_id) REFERENCES sales_invoices(id),
  CONSTRAINT fk_sii_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

CREATE TABLE customer_payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  payment_number VARCHAR(40) NOT NULL UNIQUE,
  customer_id BIGINT UNSIGNED NOT NULL,
  payment_date DATETIME NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  method ENUM('cash','bank_transfer','cheque','card','e_wallet','other') NOT NULL DEFAULT 'cash',
  reference_number VARCHAR(120) NULL,
  proof_file_path VARCHAR(500) NULL,
  status ENUM('pending_verification','verified','rejected','void') NOT NULL DEFAULT 'pending_verification',
  notes TEXT NULL,
  recorded_by BIGINT UNSIGNED NOT NULL,
  verified_by BIGINT UNSIGNED NULL,
  verified_at DATETIME NULL,
  rejection_reason VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cp_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
  CONSTRAINT fk_cp_recorder FOREIGN KEY (recorded_by) REFERENCES users(id),
  CONSTRAINT fk_cp_verifier FOREIGN KEY (verified_by) REFERENCES users(id),
  INDEX idx_cp_customer_date (customer_id, payment_date),
  INDEX idx_cp_status_date (status, payment_date),
  INDEX idx_cp_reference (reference_number)
) ENGINE=InnoDB;

CREATE TABLE customer_payment_allocations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  payment_id BIGINT UNSIGNED NOT NULL,
  invoice_id BIGINT UNSIGNED NOT NULL,
  amount_applied DECIMAL(14,2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_cpa_payment FOREIGN KEY (payment_id) REFERENCES customer_payments(id),
  CONSTRAINT fk_cpa_invoice FOREIGN KEY (invoice_id) REFERENCES sales_invoices(id),
  UNIQUE KEY uq_cpa_payment_invoice (payment_id, invoice_id),
  INDEX idx_cpa_invoice (invoice_id)
) ENGINE=InnoDB;

CREATE TABLE supplier_bills (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  bill_number VARCHAR(60) NOT NULL,
  supplier_id BIGINT UNSIGNED NOT NULL,
  purchase_order_id BIGINT UNSIGNED NULL,
  bill_date DATE NOT NULL,
  due_date DATE NULL,
  supplier_reference VARCHAR(120) NULL,
  status ENUM('draft','posted','partially_paid','paid','void') NOT NULL DEFAULT 'draft',
  subtotal DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tax_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_bill_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
  CONSTRAINT fk_bill_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id),
  CONSTRAINT fk_bill_creator FOREIGN KEY (created_by) REFERENCES users(id),
  UNIQUE KEY uq_supplier_bill (supplier_id, bill_number),
  INDEX idx_bill_due (due_date, status)
) ENGINE=InnoDB;

CREATE TABLE supplier_bill_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  supplier_bill_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NULL,
  description VARCHAR(255) NOT NULL,
  quantity DECIMAL(14,4) NOT NULL DEFAULT 1.0000,
  unit_cost DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  line_total DECIMAL(14,2) NOT NULL,
  CONSTRAINT fk_sbi_bill FOREIGN KEY (supplier_bill_id) REFERENCES supplier_bills(id),
  CONSTRAINT fk_sbi_product FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;

CREATE TABLE supplier_payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  payment_number VARCHAR(40) NOT NULL UNIQUE,
  supplier_id BIGINT UNSIGNED NOT NULL,
  payment_date DATETIME NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  method ENUM('cash','bank_transfer','cheque','card','e_wallet','other') NOT NULL DEFAULT 'bank_transfer',
  reference_number VARCHAR(120) NULL,
  status ENUM('pending_verification','verified','rejected','void') NOT NULL DEFAULT 'pending_verification',
  notes TEXT NULL,
  recorded_by BIGINT UNSIGNED NOT NULL,
  verified_by BIGINT UNSIGNED NULL,
  verified_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sp_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id),
  CONSTRAINT fk_sp_recorder FOREIGN KEY (recorded_by) REFERENCES users(id),
  CONSTRAINT fk_sp_verifier FOREIGN KEY (verified_by) REFERENCES users(id),
  INDEX idx_sp_supplier_date (supplier_id, payment_date),
  INDEX idx_sp_status (status)
) ENGINE=InnoDB;

CREATE TABLE supplier_payment_allocations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  payment_id BIGINT UNSIGNED NOT NULL,
  supplier_bill_id BIGINT UNSIGNED NOT NULL,
  amount_applied DECIMAL(14,2) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_spa_payment FOREIGN KEY (payment_id) REFERENCES supplier_payments(id),
  CONSTRAINT fk_spa_bill FOREIGN KEY (supplier_bill_id) REFERENCES supplier_bills(id),
  UNIQUE KEY uq_spa_payment_bill (payment_id, supplier_bill_id),
  INDEX idx_spa_bill (supplier_bill_id)
) ENGINE=InnoDB;

CREATE TABLE expenses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  expense_number VARCHAR(40) NOT NULL UNIQUE,
  expense_date DATE NOT NULL,
  category VARCHAR(100) NOT NULL,
  description VARCHAR(255) NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  payment_method ENUM('cash','bank_transfer','cheque','card','e_wallet','other') NOT NULL DEFAULT 'cash',
  reference_number VARCHAR(120) NULL,
  status ENUM('draft','submitted','approved','rejected','void') NOT NULL DEFAULT 'draft',
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  approved_by BIGINT UNSIGNED NULL,
  approved_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_exp_creator FOREIGN KEY (created_by) REFERENCES users(id),
  CONSTRAINT fk_exp_approver FOREIGN KEY (approved_by) REFERENCES users(id),
  INDEX idx_exp_date_category (expense_date, category),
  INDEX idx_exp_status (status)
) ENGINE=InnoDB;

CREATE TABLE expense_attachments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  expense_id BIGINT UNSIGNED NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  original_filename VARCHAR(255) NULL,
  uploaded_by BIGINT UNSIGNED NOT NULL,
  uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ea_expense FOREIGN KEY (expense_id) REFERENCES expenses(id),
  CONSTRAINT fk_ea_user FOREIGN KEY (uploaded_by) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE item_releases (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  release_number VARCHAR(40) NOT NULL UNIQUE,
  sales_order_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  release_date DATETIME NOT NULL,
  status ENUM('draft','released','cancelled') NOT NULL DEFAULT 'draft',
  released_by BIGINT UNSIGNED NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_release_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_release_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_release_user FOREIGN KEY (released_by) REFERENCES users(id),
  INDEX idx_release_date (release_date, status)
) ENGINE=InnoDB;

CREATE TABLE delivery_items (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  delivery_id BIGINT UNSIGNED NOT NULL,
  sales_order_item_id BIGINT UNSIGNED NOT NULL,
  quantity DECIMAL(14,4) NOT NULL,
  CONSTRAINT fk_di_sales_item FOREIGN KEY (sales_order_item_id) REFERENCES sales_order_items(id)
) ENGINE=InnoDB;

CREATE TABLE deliveries (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  delivery_number VARCHAR(40) NOT NULL UNIQUE,
  sales_order_id BIGINT UNSIGNED NOT NULL,
  release_id BIGINT UNSIGNED NULL,
  scheduled_start DATETIME NOT NULL,
  scheduled_end DATETIME NULL,
  delivery_address VARCHAR(255) NULL,
  contact_person VARCHAR(160) NULL,
  contact_phone VARCHAR(40) NULL,
  status ENUM('scheduled','in_transit','delivered','failed','cancelled') NOT NULL DEFAULT 'scheduled',
  google_calendar_event_id VARCHAR(255) NULL,
  driver_or_courier VARCHAR(160) NULL,
  delivered_at DATETIME NULL,
  proof_of_delivery_path VARCHAR(500) NULL,
  notes TEXT NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_delivery_order FOREIGN KEY (sales_order_id) REFERENCES sales_orders(id),
  CONSTRAINT fk_delivery_release FOREIGN KEY (release_id) REFERENCES item_releases(id),
  CONSTRAINT fk_delivery_creator FOREIGN KEY (created_by) REFERENCES users(id),
  INDEX idx_delivery_schedule (scheduled_start, status),
  INDEX idx_delivery_order (sales_order_id)
) ENGINE=InnoDB;

ALTER TABLE delivery_items
  ADD CONSTRAINT fk_di_delivery FOREIGN KEY (delivery_id) REFERENCES deliveries(id);

CREATE TABLE calendar_events (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  delivery_id BIGINT UNSIGNED NULL,
  provider ENUM('google') NOT NULL DEFAULT 'google',
  external_event_id VARCHAR(255) NOT NULL,
  sync_status ENUM('pending','synced','failed','deleted') NOT NULL DEFAULT 'pending',
  last_synced_at DATETIME NULL,
  last_error TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_calendar_delivery FOREIGN KEY (delivery_id) REFERENCES deliveries(id),
  UNIQUE KEY uq_calendar_provider_event (provider, external_event_id),
  UNIQUE KEY uq_calendar_delivery (delivery_id)
) ENGINE=InnoDB;

CREATE TABLE stock_movements (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  warehouse_id BIGINT UNSIGNED NOT NULL,
  movement_type ENUM('opening','purchase_receipt','sale_release','customer_return','supplier_return','adjustment_in','adjustment_out','transfer_in','transfer_out','void_reversal') NOT NULL,
  quantity_change DECIMAL(14,4) NOT NULL,
  unit_cost DECIMAL(14,4) NOT NULL DEFAULT 0.0000,
  reference_type VARCHAR(40) NULL,
  reference_id BIGINT UNSIGNED NULL,
  movement_date DATETIME NOT NULL,
  notes VARCHAR(255) NULL,
  created_by BIGINT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sm_product FOREIGN KEY (product_id) REFERENCES products(id),
  CONSTRAINT fk_sm_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(id),
  CONSTRAINT fk_sm_user FOREIGN KEY (created_by) REFERENCES users(id),
  INDEX idx_sm_product_warehouse_date (product_id, warehouse_id, movement_date),
  INDEX idx_sm_reference (reference_type, reference_id),
  INDEX idx_sm_date (movement_date)
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NULL,
  action VARCHAR(80) NOT NULL,
  entity_type VARCHAR(80) NOT NULL,
  entity_id BIGINT UNSIGNED NULL,
  old_values JSON NULL,
  new_values JSON NULL,
  ip_address VARCHAR(45) NULL,
  user_agent VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_audit_entity (entity_type, entity_id),
  INDEX idx_audit_user_date (user_id, created_at)
) ENGINE=InnoDB;

-- Starter roles
INSERT INTO roles (role_name, description) VALUES
('admin', 'Full system administration'),
('manager', 'Approvals, operational oversight, and reports'),
('sales', 'Customers, quotations, sales orders, and invoices'),
('purchasing', 'Suppliers and purchase orders'),
('inventory_staff', 'Receiving, stock movements, and item releasing'),
('accounting', 'Receivables, payables, payment verification, and expenses'),
('delivery_staff', 'Delivery schedules and delivery status');

-- Starter permissions
INSERT INTO permissions (permission_code, description) VALUES
('invoices.create', 'Create sales invoices'),
('invoices.delete', 'Delete/Void sales invoices'),
('reports.view', 'View financial and operational reports'),
('payments.verify', 'Verify customer or supplier payments'),
('inventory.adjust', 'Make stock adjustments'),
('goods_receipts.post', 'Post draft goods receipts into inventory');

-- Example mapping: give admin all permissions (or handle via application wildcards)
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p WHERE r.role_name = 'admin';

-- Suggested starter units.
INSERT INTO units_of_measure (unit_code, unit_name, decimal_places) VALUES
('PC', 'Piece', 0),
('BOX', 'Box', 0),
('KG', 'Kilogram', 3),
('L', 'Liter', 3),
('SET', 'Set', 0);

-- Suggested report views.
CREATE OR REPLACE VIEW v_customer_invoice_balances AS
SELECT
  i.id AS invoice_id,
  i.invoice_number,
  i.customer_id,
  c.customer_name,
  i.invoice_date,
  i.due_date,
  i.total_amount,
  COALESCE(SUM(
    CASE WHEN p.status = 'verified' THEN a.amount_applied ELSE 0 END
  ), 0.00) AS paid_amount,
  i.total_amount - COALESCE(SUM(
    CASE WHEN p.status = 'verified' THEN a.amount_applied ELSE 0 END
  ), 0.00) AS outstanding_amount
FROM sales_invoices i
JOIN customers c ON c.id = i.customer_id
LEFT JOIN customer_payment_allocations a ON a.invoice_id = i.id
LEFT JOIN customer_payments p ON p.id = a.payment_id
WHERE i.status <> 'void'
GROUP BY i.id, i.invoice_number, i.customer_id, c.customer_name,
         i.invoice_date, i.due_date, i.total_amount;

CREATE OR REPLACE VIEW v_supplier_bill_balances AS
SELECT
  b.id AS bill_id,
  b.bill_number,
  b.supplier_id,
  s.supplier_name,
  b.bill_date,
  b.due_date,
  b.total_amount,
  COALESCE(SUM(
    CASE WHEN p.status = 'verified' THEN a.amount_applied ELSE 0 END
  ), 0.00) AS paid_amount,
  b.total_amount - COALESCE(SUM(
    CASE WHEN p.status = 'verified' THEN a.amount_applied ELSE 0 END
  ), 0.00) AS outstanding_amount
FROM supplier_bills b
JOIN suppliers s ON s.id = b.supplier_id
LEFT JOIN supplier_payment_allocations a ON a.supplier_bill_id = b.id
LEFT JOIN supplier_payments p ON p.id = a.payment_id
WHERE b.status <> 'void'
GROUP BY b.id, b.bill_number, b.supplier_id, s.supplier_name,
         b.bill_date, b.due_date, b.total_amount;