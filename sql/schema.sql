
BEGIN;

-- 1. Клиенты
CREATE TABLE clients (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(254) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id BIGINT UNIQUE
);


-- 2. Автомобили
CREATE TABLE cars (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id BIGINT NOT NULL,
    vin VARCHAR(17) NOT NULL UNIQUE,
    license_plate VARCHAR(15) NOT NULL UNIQUE,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year SMALLINT NOT NULL,
    mileage INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT fk_cars_client
        FOREIGN KEY (client_id)
        REFERENCES clients(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_cars_vin
        CHECK (vin ~ '^[A-HJ-NPR-Z0-9]{17}$'),

    CONSTRAINT chk_cars_year
        CHECK (year >= 1950),

    CONSTRAINT chk_cars_mileage
        CHECK (mileage >= 0)
);


-- 3. Сотрудники
CREATE TABLE employees (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(200) NOT NULL,
    role VARCHAR(20) NOT NULL,
    hourly_rate NUMERIC(10, 2) NOT NULL,
    hired_at DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT chk_employees_role
        CHECK (role IN ('mechanic', 'manager', 'admin')),

    CONSTRAINT chk_employees_hourly_rate
        CHECK (hourly_rate > 0)
);


-- 4. Рабочие боксы
CREATE TABLE work_bays (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    bay_type VARCHAR(100) NOT NULL,
    is_operational BOOLEAN NOT NULL DEFAULT TRUE
);


-- 5. Услуги
CREATE TABLE services (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    base_price NUMERIC(10, 2) NOT NULL,
    norm_hours NUMERIC(5, 2) NOT NULL,

    CONSTRAINT chk_services_base_price
        CHECK (base_price > 0),

    CONSTRAINT chk_services_norm_hours
        CHECK (norm_hours > 0)
);


-- 6. Запчасти
CREATE TABLE parts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    manufacturer VARCHAR(100) NOT NULL,
    purchase_price NUMERIC(10, 2) NOT NULL,
    sale_price NUMERIC(10, 2) NOT NULL,
    stock_qty INTEGER NOT NULL DEFAULT 0,
    min_stock_qty INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT chk_parts_purchase_price
        CHECK (purchase_price >= 0),

    CONSTRAINT chk_parts_sale_price
        CHECK (sale_price >= purchase_price),

    CONSTRAINT chk_parts_stock_qty
        CHECK (stock_qty >= 0),

    CONSTRAINT chk_parts_min_stock_qty
        CHECK (min_stock_qty >= 0)
);


-- 7. Заказы-наряды и записи на обслуживание
CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    car_id BIGINT NOT NULL,
    manager_id BIGINT,
    bay_id BIGINT,
    status VARCHAR(20) NOT NULL DEFAULT 'new',
    booking_source VARCHAR(10) NOT NULL DEFAULT 'staff',
    scheduled_start TIMESTAMP NOT NULL,
    scheduled_end TIMESTAMP NOT NULL,
    completed_at TIMESTAMP,
    total_cost NUMERIC(12, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_orders_car
        FOREIGN KEY (car_id)
        REFERENCES cars(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_orders_manager
        FOREIGN KEY (manager_id)
        REFERENCES employees(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_orders_bay
        FOREIGN KEY (bay_id)
        REFERENCES work_bays(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_orders_status
        CHECK (status IN (
            'new',
            'diagnostics',
            'in_progress',
            'ready',
            'closed',
            'cancelled'
        )),

    CONSTRAINT chk_orders_booking_source
        CHECK (booking_source IN ('website', 'staff')),

    CONSTRAINT chk_orders_schedule
        CHECK (scheduled_end > scheduled_start),

    CONSTRAINT chk_orders_completed_at
        CHECK (
            completed_at IS NULL
            OR completed_at >= scheduled_start
        ),

    CONSTRAINT chk_orders_total_cost
        CHECK (total_cost >= 0)
);


-- 8. Услуги в заказах
CREATE TABLE order_services (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,
    mechanic_id BIGINT,
    quantity INTEGER NOT NULL DEFAULT 1,
    price_at_order NUMERIC(10, 2) NOT NULL,

    CONSTRAINT fk_order_services_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_order_services_service
        FOREIGN KEY (service_id)
        REFERENCES services(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_order_services_mechanic
        FOREIGN KEY (mechanic_id)
        REFERENCES employees(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_order_services_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_order_services_price
        CHECK (price_at_order >= 0)
);


-- 9. Запчасти в заказах
CREATE TABLE order_parts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL,
    part_id BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    price_at_order NUMERIC(10, 2) NOT NULL,

    CONSTRAINT fk_order_parts_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_order_parts_part
        FOREIGN KEY (part_id)
        REFERENCES parts(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_order_parts_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_order_parts_price
        CHECK (price_at_order >= 0)
);


-- 10. Платежи
CREATE TABLE payments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    method VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMP,

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_payments_amount
        CHECK (amount > 0),

    CONSTRAINT chk_payments_method
        CHECK (method IN ('cash', 'card', 'transfer')),

    CONSTRAINT chk_payments_status
        CHECK (status IN ('pending', 'paid', 'refunded'))
);


-- 11. История изменения статусов заказов
CREATE TABLE order_status_history (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id BIGINT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_by BIGINT,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    comment TEXT,

    CONSTRAINT fk_status_history_order
        FOREIGN KEY (order_id)
        REFERENCES orders(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_status_history_employee
        FOREIGN KEY (changed_by)
        REFERENCES employees(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT chk_status_history_old_new
        CHECK (old_status IS NULL OR old_status <> new_status),

    CONSTRAINT chk_status_history_new_status
        CHECK (new_status IN (
            'new',
            'diagnostics',
            'in_progress',
            'ready',
            'closed',
            'cancelled'
        ))
);

COMMIT;