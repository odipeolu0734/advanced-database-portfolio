-- ============================================================================
-- Portfolio 3: Transactions — ShopEase E-commerce Platform
-- ============================================================================
-- This file demonstrates PostgreSQL transactions in realistic e-commerce
-- scenarios. Each transaction block includes detailed commentary on the
-- ACID properties being exercised.
--
-- Prerequisites: The shopease schema and tables must exist (see Portfolio 1).
-- ============================================================================

-- Set the search path for convenience
SET search_path TO shopease, public;


-- ============================================================================
-- TRANSACTION 1: ORDER PLACEMENT
-- ============================================================================
-- Business Process: A customer places an order for one or more products.
--
-- ACID Properties Demonstrated:
--   Atomicity  — All six steps succeed or none take effect. If payment fails,
--                the order, line items, and inventory changes are all undone.
--   Consistency — CHECK constraints (inventory.quantity >= 0) and FOREIGN KEY
--                 constraints are enforced at every step. The database never
--                 enters an invalid state.
--   Isolation  — SELECT FOR UPDATE locks inventory rows so concurrent orders
--                for the same product are serialised. No two transactions can
--                oversell the last item.
--   Durability — Once COMMIT returns, the order, payment, and shipping records
--                are persisted to the WAL and survive crashes.
-- ============================================================================

DO $$
DECLARE
    v_customer_id    INT := 1;          -- The customer placing the order
    v_product_id_1   INT := 1;          -- First product to order
    v_product_id_2   INT := 3;          -- Second product to order
    v_quantity_1     INT := 2;          -- Quantity of first product
    v_quantity_2     INT := 1;          -- Quantity of second product
    v_price_1        NUMERIC(10,2);     -- Unit price of first product
    v_price_2        NUMERIC(10,2);     -- Unit price of second product
    v_stock_1        INT;               -- Available stock for product 1
    v_stock_2        INT;               -- Available stock for product 2
    v_order_id       INT;               -- Generated order ID
    v_payment_id     INT;               -- Generated payment ID
    v_total_amount   NUMERIC(10,2);     -- Computed order total
    v_address_id     INT;               -- Shipping address
BEGIN
    RAISE NOTICE '=== TRANSACTION 1: ORDER PLACEMENT ===';
    RAISE NOTICE 'Customer % is placing an order...', v_customer_id;

    -- -----------------------------------------------------------------------
    -- STEP 1: Lock and check inventory (Pessimistic Locking)
    -- FOR UPDATE ensures no other transaction can modify these rows until
    -- this transaction completes. This prevents the "lost update" problem
    -- where two customers both see quantity=1 and both try to buy it.
    -- -----------------------------------------------------------------------
    SELECT quantity INTO v_stock_1
    FROM inventory
    WHERE product_id = v_product_id_1
    FOR UPDATE;

    IF v_stock_1 IS NULL OR v_stock_1 < v_quantity_1 THEN
        RAISE EXCEPTION 'Insufficient stock for product %. Available: %, Requested: %',
            v_product_id_1, COALESCE(v_stock_1, 0), v_quantity_1;
    END IF;

    SELECT quantity INTO v_stock_2
    FROM inventory
    WHERE product_id = v_product_id_2
    FOR UPDATE;

    IF v_stock_2 IS NULL OR v_stock_2 < v_quantity_2 THEN
        RAISE EXCEPTION 'Insufficient stock for product %. Available: %, Requested: %',
            v_product_id_2, COALESCE(v_stock_2, 0), v_quantity_2;
    END IF;

    RAISE NOTICE 'Inventory check passed. Product %: % available, Product %: % available.',
        v_product_id_1, v_stock_1, v_product_id_2, v_stock_2;

    -- -----------------------------------------------------------------------
    -- STEP 2: Retrieve product prices
    -- -----------------------------------------------------------------------
    SELECT price INTO v_price_1 FROM products WHERE product_id = v_product_id_1;
    SELECT price INTO v_price_2 FROM products WHERE product_id = v_product_id_2;

    v_total_amount := (v_price_1 * v_quantity_1) + (v_price_2 * v_quantity_2);

    RAISE NOTICE 'Order total calculated: £%', v_total_amount;

    -- -----------------------------------------------------------------------
    -- STEP 3: Get the customer's default shipping address
    -- -----------------------------------------------------------------------
    SELECT address_id INTO v_address_id
    FROM addresses
    WHERE customer_id = v_customer_id
      AND is_default = TRUE
    LIMIT 1;

    IF v_address_id IS NULL THEN
        RAISE EXCEPTION 'No default address found for customer %', v_customer_id;
    END IF;

    -- -----------------------------------------------------------------------
    -- STEP 4: Create the order record
    -- Consistency: The FK constraint on customer_id and address_id ensures
    -- both the customer and address exist.
    -- -----------------------------------------------------------------------
    INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_address_id)
    VALUES (v_customer_id, NOW(), 'pending', v_total_amount, v_address_id)
    RETURNING order_id INTO v_order_id;

    RAISE NOTICE 'Order created with ID: %', v_order_id;

    -- -----------------------------------------------------------------------
    -- STEP 5: Create order items
    -- -----------------------------------------------------------------------
    INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal)
    VALUES
        (v_order_id, v_product_id_1, v_quantity_1, v_price_1, v_price_1 * v_quantity_1),
        (v_order_id, v_product_id_2, v_quantity_2, v_price_2, v_price_2 * v_quantity_2);

    RAISE NOTICE 'Order items created for order %', v_order_id;

    -- -----------------------------------------------------------------------
    -- STEP 6: Deduct inventory
    -- Consistency: The CHECK constraint (quantity >= 0) acts as a final
    -- safety net. Even if our application logic has a bug, the database
    -- will reject a negative inventory value.
    -- -----------------------------------------------------------------------
    UPDATE inventory
    SET quantity = quantity - v_quantity_1,
        last_updated = NOW()
    WHERE product_id = v_product_id_1;

    UPDATE inventory
    SET quantity = quantity - v_quantity_2,
        last_updated = NOW()
    WHERE product_id = v_product_id_2;

    RAISE NOTICE 'Inventory deducted: Product % (-%  units), Product % (-% units)',
        v_product_id_1, v_quantity_1, v_product_id_2, v_quantity_2;

    -- -----------------------------------------------------------------------
    -- STEP 7: Process payment
    -- Atomicity: If this step fails (e.g., invalid payment method), the
    -- entire transaction is rolled back — the order, items, and inventory
    -- changes are all undone automatically.
    -- -----------------------------------------------------------------------
    INSERT INTO payments (order_id, payment_date, amount, payment_method, payment_status)
    VALUES (v_order_id, NOW(), v_total_amount, 'credit_card', 'completed')
    RETURNING payment_id INTO v_payment_id;

    -- Update order status to confirmed after successful payment
    UPDATE orders
    SET status = 'confirmed'
    WHERE order_id = v_order_id;

    RAISE NOTICE 'Payment % processed: £% via credit_card', v_payment_id, v_total_amount;

    -- -----------------------------------------------------------------------
    -- STEP 8: Create shipping record
    -- -----------------------------------------------------------------------
    INSERT INTO shipping (order_id, shipping_method, shipping_status, estimated_delivery, shipping_cost)
    VALUES (v_order_id, 'standard', 'processing', NOW() + INTERVAL '5 days', 4.99);

    RAISE NOTICE 'Shipping record created for order %', v_order_id;

    -- -----------------------------------------------------------------------
    -- STEP 9: Clear the customer's cart (cleanup)
    -- -----------------------------------------------------------------------
    DELETE FROM cart_items
    WHERE cart_id IN (SELECT cart_id FROM shopping_cart WHERE customer_id = v_customer_id);

    RAISE NOTICE '=== ORDER PLACEMENT COMPLETE — Order % committed successfully ===', v_order_id;

    -- Durability: At this point, COMMIT occurs (implicit at END of DO block),
    -- and all changes are written to the WAL. Even a server crash immediately
    -- after this point will not lose the order.

EXCEPTION
    WHEN check_violation THEN
        -- This catches the inventory quantity >= 0 constraint
        RAISE NOTICE 'ERROR: Inventory constraint violated — rolling back entire order.';
        RAISE NOTICE 'Detail: %', SQLERRM;
        -- Atomicity: The entire transaction is rolled back automatically
        -- when an exception propagates out of the block.

    WHEN foreign_key_violation THEN
        RAISE NOTICE 'ERROR: Foreign key violation — invalid reference. Rolling back.';
        RAISE NOTICE 'Detail: %', SQLERRM;

    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Unexpected error during order placement — rolling back.';
        RAISE NOTICE 'SQLSTATE: %, Message: %', SQLSTATE, SQLERRM;
END;
$$;


-- ============================================================================
-- TRANSACTION 2: PAYMENT REVERSAL / REFUND
-- ============================================================================
-- Business Process: A customer requests a refund. The system must reverse the
-- payment, update the order status, and restore inventory quantities.
--
-- ACID Properties Demonstrated:
--   Atomicity  — Payment reversal, order status change, and inventory
--                restoration are all-or-nothing. We cannot have a refund
--                issued but inventory not restored.
--   Consistency — The order transitions through defined statuses. The refund
--                 amount matches the original payment. Inventory is correctly
--                 restored.
--   Isolation  — Row locks prevent another process from modifying the same
--                order or inventory rows concurrently.
--   Durability — Once committed, the refund is permanent and auditable.
-- ============================================================================

DO $$
DECLARE
    v_order_id         INT := 1;          -- Order to refund
    v_original_amount  NUMERIC(10,2);
    v_order_status     VARCHAR(50);
    v_payment_status   VARCHAR(50);
    v_item             RECORD;
BEGIN
    RAISE NOTICE '=== TRANSACTION 2: PAYMENT REVERSAL / REFUND ===';

    -- -----------------------------------------------------------------------
    -- STEP 1: Lock and validate the order
    -- FOR UPDATE locks the row to prevent concurrent refund attempts.
    -- -----------------------------------------------------------------------
    SELECT status, total_amount
    INTO v_order_status, v_original_amount
    FROM orders
    WHERE order_id = v_order_id
    FOR UPDATE;

    IF v_order_status IS NULL THEN
        RAISE EXCEPTION 'Order % not found', v_order_id;
    END IF;

    IF v_order_status IN ('refunded', 'cancelled') THEN
        RAISE EXCEPTION 'Order % has already been % — cannot refund', v_order_id, v_order_status;
    END IF;

    RAISE NOTICE 'Order % found. Status: %, Amount: £%', v_order_id, v_order_status, v_original_amount;

    -- -----------------------------------------------------------------------
    -- STEP 2: Validate and reverse the payment
    -- -----------------------------------------------------------------------
    SELECT payment_status INTO v_payment_status
    FROM payments
    WHERE order_id = v_order_id
    FOR UPDATE;

    IF v_payment_status != 'completed' THEN
        RAISE EXCEPTION 'Payment for order % is not completed (status: %) — cannot refund',
            v_order_id, v_payment_status;
    END IF;

    UPDATE payments
    SET payment_status = 'refunded',
        payment_date = NOW()
    WHERE order_id = v_order_id;

    RAISE NOTICE 'Payment reversed for order %: £% refunded', v_order_id, v_original_amount;

    -- -----------------------------------------------------------------------
    -- STEP 3: Restore inventory for each order item
    -- We iterate through all items in the order and add back quantities.
    -- Consistency: Inventory quantities return to their pre-order values.
    -- -----------------------------------------------------------------------
    FOR v_item IN
        SELECT product_id, quantity
        FROM order_items
        WHERE order_id = v_order_id
    LOOP
        UPDATE inventory
        SET quantity = quantity + v_item.quantity,
            last_updated = NOW()
        WHERE product_id = v_item.product_id;

        RAISE NOTICE 'Restored % units to product % inventory', v_item.quantity, v_item.product_id;
    END LOOP;

    -- -----------------------------------------------------------------------
    -- STEP 4: Update order status
    -- -----------------------------------------------------------------------
    UPDATE orders
    SET status = 'refunded'
    WHERE order_id = v_order_id;

    -- -----------------------------------------------------------------------
    -- STEP 5: Cancel shipping if still in processing
    -- -----------------------------------------------------------------------
    UPDATE shipping
    SET shipping_status = 'cancelled'
    WHERE order_id = v_order_id
      AND shipping_status IN ('processing', 'shipped');

    RAISE NOTICE '=== REFUND COMPLETE — Order % refunded, £% returned ===', v_order_id, v_original_amount;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Refund failed for order %. Rolling back all changes.';
        RAISE NOTICE 'SQLSTATE: %, Message: %', SQLSTATE, SQLERRM;
END;
$$;


-- ============================================================================
-- TRANSACTION 3: BATCH INVENTORY UPDATE
-- ============================================================================
-- Business Process: A warehouse receives a shipment and needs to update
-- inventory quantities for multiple products in a single atomic operation.
--
-- ACID Properties Demonstrated:
--   Atomicity  — Either ALL product quantities are updated, or NONE are.
--                A partial update (e.g., 3 out of 5 products updated) would
--                leave inventory in an inconsistent state.
--   Consistency — All updated quantities must satisfy CHECK constraints.
--   Isolation  — FOR UPDATE ensures no concurrent orders can deduct from
--                these products while the batch update is in progress.
--   Durability — The updated stock levels persist after commit.
-- ============================================================================

DO $$
DECLARE
    v_update RECORD;
    v_total_updated INT := 0;
BEGIN
    RAISE NOTICE '=== TRANSACTION 3: BATCH INVENTORY UPDATE ===';
    RAISE NOTICE 'Processing warehouse shipment...';

    -- -----------------------------------------------------------------------
    -- Create a temporary table with the shipment data
    -- In production, this would come from an external source (API, CSV import)
    -- -----------------------------------------------------------------------
    CREATE TEMP TABLE IF NOT EXISTS shipment_items (
        product_id    INT,
        qty_received  INT
    ) ON COMMIT DROP;  -- Temporary table is dropped when the transaction commits

    INSERT INTO shipment_items (product_id, qty_received) VALUES
        (1, 50),    -- 50 units of product 1
        (2, 30),    -- 30 units of product 2
        (3, 75),    -- 75 units of product 3
        (5, 20),    -- 20 units of product 5
        (7, 100);   -- 100 units of product 7

    -- -----------------------------------------------------------------------
    -- Lock all target inventory rows in a consistent order (by product_id)
    -- to prevent deadlocks with concurrent transactions.
    -- -----------------------------------------------------------------------
    PERFORM i.product_id
    FROM inventory i
    JOIN shipment_items s ON i.product_id = s.product_id
    ORDER BY i.product_id
    FOR UPDATE OF i;

    -- -----------------------------------------------------------------------
    -- Apply the batch update atomically
    -- -----------------------------------------------------------------------
    FOR v_update IN
        SELECT s.product_id, s.qty_received, i.quantity AS old_qty
        FROM shipment_items s
        JOIN inventory i ON s.product_id = i.product_id
        ORDER BY s.product_id
    LOOP
        UPDATE inventory
        SET quantity = quantity + v_update.qty_received,
            last_updated = NOW()
        WHERE product_id = v_update.product_id;

        v_total_updated := v_total_updated + 1;

        RAISE NOTICE 'Product %: % → % (+% units)',
            v_update.product_id,
            v_update.old_qty,
            v_update.old_qty + v_update.qty_received,
            v_update.qty_received;
    END LOOP;

    RAISE NOTICE '=== BATCH UPDATE COMPLETE — % products updated atomically ===', v_total_updated;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Batch update failed. ALL changes rolled back.';
        RAISE NOTICE 'SQLSTATE: %, Message: %', SQLSTATE, SQLERRM;
        -- Atomicity in action: none of the inventory updates persist
END;
$$;


-- ============================================================================
-- TRANSACTION 4: CUSTOMER ACCOUNT OPERATIONS
-- ============================================================================
-- Business Process: Update a customer's profile information atomically,
-- including email change with uniqueness verification, and transfer store
-- credits between customer accounts (e.g., gift or promotional transfer).
--
-- ACID Properties Demonstrated:
--   Atomicity  — Credit transfer is all-or-nothing: the debit from one
--                account and credit to another both succeed or both fail.
--   Consistency — Total credits in the system remain constant (conservation
--                 invariant). The sender cannot go below zero.
--   Isolation  — FOR UPDATE on both customer rows prevents concurrent
--                transfers from corrupting the balance.
--   Durability — Committed transfers are permanent.
-- ============================================================================

DO $$
DECLARE
    v_sender_id       INT := 1;
    v_receiver_id     INT := 2;
    v_transfer_amount NUMERIC(10,2) := 25.00;
    v_sender_balance  NUMERIC(10,2);
    v_receiver_balance NUMERIC(10,2);
    v_sender_email    VARCHAR(255);
    v_new_email       VARCHAR(255) := 'john.doe.updated@email.com';
    v_email_exists    BOOLEAN;
BEGIN
    RAISE NOTICE '=== TRANSACTION 4: CUSTOMER ACCOUNT OPERATIONS ===';

    -- -----------------------------------------------------------------------
    -- PART A: Atomic Profile Update with Uniqueness Check
    -- -----------------------------------------------------------------------
    RAISE NOTICE '--- Part A: Atomic Profile Update ---';

    -- Lock the customer row to prevent concurrent modifications
    SELECT email INTO v_sender_email
    FROM customers
    WHERE customer_id = v_sender_id
    FOR UPDATE;

    -- Check if the new email is already in use
    SELECT EXISTS(
        SELECT 1 FROM customers
        WHERE email = v_new_email AND customer_id != v_sender_id
    ) INTO v_email_exists;

    IF v_email_exists THEN
        RAISE EXCEPTION 'Email % is already in use by another customer', v_new_email;
    END IF;

    -- Update the email atomically
    UPDATE customers
    SET email = v_new_email,
        updated_at = NOW()
    WHERE customer_id = v_sender_id;

    RAISE NOTICE 'Customer % email updated: % → %', v_sender_id, v_sender_email, v_new_email;

    -- -----------------------------------------------------------------------
    -- PART B: Store Credit Transfer
    -- Lock both accounts in a consistent order (lower ID first) to prevent
    -- deadlocks when concurrent transfers occur between the same accounts.
    -- -----------------------------------------------------------------------
    RAISE NOTICE '--- Part B: Store Credit Transfer ---';

    -- Lock accounts in order of customer_id to prevent deadlocks
    IF v_sender_id < v_receiver_id THEN
        SELECT store_credit INTO v_sender_balance
        FROM customers WHERE customer_id = v_sender_id FOR UPDATE;

        SELECT store_credit INTO v_receiver_balance
        FROM customers WHERE customer_id = v_receiver_id FOR UPDATE;
    ELSE
        SELECT store_credit INTO v_receiver_balance
        FROM customers WHERE customer_id = v_receiver_id FOR UPDATE;

        SELECT store_credit INTO v_sender_balance
        FROM customers WHERE customer_id = v_sender_id FOR UPDATE;
    END IF;

    RAISE NOTICE 'Sender balance: £%, Receiver balance: £%', v_sender_balance, v_receiver_balance;

    -- Validate sufficient balance
    IF v_sender_balance < v_transfer_amount THEN
        RAISE EXCEPTION 'Insufficient store credit. Available: £%, Required: £%',
            v_sender_balance, v_transfer_amount;
    END IF;

    -- Perform the transfer (debit sender, credit receiver)
    -- Consistency: total credits in the system remain constant
    UPDATE customers
    SET store_credit = store_credit - v_transfer_amount,
        updated_at = NOW()
    WHERE customer_id = v_sender_id;

    UPDATE customers
    SET store_credit = store_credit + v_transfer_amount,
        updated_at = NOW()
    WHERE customer_id = v_receiver_id;

    RAISE NOTICE 'Transfer complete: £% from customer % → customer %', 
        v_transfer_amount, v_sender_id, v_receiver_id;
    RAISE NOTICE 'New balances — Sender: £%, Receiver: £%',
        v_sender_balance - v_transfer_amount,
        v_receiver_balance + v_transfer_amount;

    RAISE NOTICE '=== CUSTOMER ACCOUNT OPERATIONS COMPLETE ===';

EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'ERROR: Email uniqueness constraint violated. Rolling back.';
    WHEN check_violation THEN
        RAISE NOTICE 'ERROR: Store credit cannot be negative. Rolling back.';
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Account operation failed. SQLSTATE: %, Message: %', SQLSTATE, SQLERRM;
END;
$$;


-- ============================================================================
-- TRANSACTION 5: SAVEPOINT USAGE — Order with Optional Extras
-- ============================================================================
-- Business Process: A customer places an order. After the core order is
-- created, the system attempts to apply a promotional coupon and add a
-- gift wrapping service. These optional steps may fail without aborting
-- the entire order.
--
-- ACID Properties Demonstrated:
--   Atomicity  — The core order (steps 1–4) is atomic. Optional extras
--                use SAVEPOINTs so their failure doesn't roll back the
--                entire transaction — only the failing extra is undone.
--   Consistency — The order total is recalculated after coupon
--                 application/rollback to maintain correct totals.
--   Isolation  — Inventory locks are held throughout, ensuring no
--                concurrent modification.
--   Durability — The final committed state (with or without extras)
--                is durable.
--
-- SAVEPOINTs allow fine-grained control: we can roll back to a named
-- point within a transaction without aborting the entire transaction.
-- This is invaluable for "best-effort" operations.
-- ============================================================================

DO $$
DECLARE
    v_customer_id     INT := 2;
    v_product_id      INT := 5;
    v_quantity         INT := 1;
    v_price           NUMERIC(10,2);
    v_stock           INT;
    v_order_id        INT;
    v_total_amount    NUMERIC(10,2);
    v_discount        NUMERIC(10,2) := 0;
    v_coupon_code     VARCHAR(50) := 'SAVE20PERCENT';
    v_address_id      INT;
    v_gift_wrap_fee   NUMERIC(10,2) := 3.99;
BEGIN
    RAISE NOTICE '=== TRANSACTION 5: SAVEPOINT USAGE — ORDER WITH OPTIONAL EXTRAS ===';

    -- -----------------------------------------------------------------------
    -- CORE ORDER (must succeed for the transaction to commit)
    -- -----------------------------------------------------------------------

    -- Lock and check inventory
    SELECT quantity INTO v_stock
    FROM inventory
    WHERE product_id = v_product_id
    FOR UPDATE;

    IF v_stock < v_quantity THEN
        RAISE EXCEPTION 'Insufficient stock for product %', v_product_id;
    END IF;

    -- Get product price
    SELECT price INTO v_price FROM products WHERE product_id = v_product_id;
    v_total_amount := v_price * v_quantity;

    -- Get shipping address
    SELECT address_id INTO v_address_id
    FROM addresses
    WHERE customer_id = v_customer_id AND is_default = TRUE
    LIMIT 1;

    -- Create order
    INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_address_id)
    VALUES (v_customer_id, NOW(), 'pending', v_total_amount, v_address_id)
    RETURNING order_id INTO v_order_id;

    -- Create order item
    INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal)
    VALUES (v_order_id, v_product_id, v_quantity, v_price, v_price * v_quantity);

    -- Deduct inventory
    UPDATE inventory
    SET quantity = quantity - v_quantity, last_updated = NOW()
    WHERE product_id = v_product_id;

    RAISE NOTICE 'Core order % created. Subtotal: £%', v_order_id, v_total_amount;

    -- -----------------------------------------------------------------------
    -- SAVEPOINT 1: Apply promotional coupon (optional — may fail)
    -- If the coupon is invalid or expired, we roll back only this step.
    -- -----------------------------------------------------------------------
    SAVEPOINT apply_coupon;

    BEGIN
        RAISE NOTICE 'Attempting to apply coupon: %...', v_coupon_code;

        -- Simulate coupon validation
        -- In production, this would query a coupons table
        IF v_coupon_code = 'SAVE20PERCENT' THEN
            v_discount := v_total_amount * 0.20;
            v_total_amount := v_total_amount - v_discount;

            UPDATE orders
            SET total_amount = v_total_amount
            WHERE order_id = v_order_id;

            RAISE NOTICE 'Coupon applied! Discount: £%, New total: £%', v_discount, v_total_amount;

            RELEASE SAVEPOINT apply_coupon;  -- Savepoint no longer needed
        ELSE
            RAISE EXCEPTION 'Invalid coupon code: %', v_coupon_code;
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- Roll back ONLY the coupon application, not the entire order
            ROLLBACK TO SAVEPOINT apply_coupon;
            RAISE NOTICE 'Coupon application failed (%). Order continues without discount.', SQLERRM;
    END;

    -- -----------------------------------------------------------------------
    -- SAVEPOINT 2: Add gift wrapping (optional — may fail)
    -- If the gift wrap service is unavailable, we proceed without it.
    -- -----------------------------------------------------------------------
    SAVEPOINT add_gift_wrap;

    BEGIN
        RAISE NOTICE 'Attempting to add gift wrapping (£%)...', v_gift_wrap_fee;

        -- Simulate: gift wrapping is available for this order
        v_total_amount := v_total_amount + v_gift_wrap_fee;

        UPDATE orders
        SET total_amount = v_total_amount
        WHERE order_id = v_order_id;

        RAISE NOTICE 'Gift wrapping added. Final total: £%', v_total_amount;

        RELEASE SAVEPOINT add_gift_wrap;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT add_gift_wrap;
            RAISE NOTICE 'Gift wrapping unavailable (%). Proceeding without it.', SQLERRM;
    END;

    -- -----------------------------------------------------------------------
    -- FINAL STEPS: Payment and shipping (must succeed)
    -- -----------------------------------------------------------------------
    INSERT INTO payments (order_id, payment_date, amount, payment_method, payment_status)
    VALUES (v_order_id, NOW(), v_total_amount, 'debit_card', 'completed');

    UPDATE orders SET status = 'confirmed' WHERE order_id = v_order_id;

    INSERT INTO shipping (order_id, shipping_method, shipping_status, estimated_delivery, shipping_cost)
    VALUES (v_order_id, 'express', 'processing', NOW() + INTERVAL '2 days', 7.99);

    RAISE NOTICE '=== ORDER % COMPLETE ===', v_order_id;
    RAISE NOTICE 'Final total: £% (discount: £%, gift wrap: £%)',
        v_total_amount, v_discount, v_gift_wrap_fee;
    RAISE NOTICE 'Savepoints allowed optional extras to fail gracefully.';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'CRITICAL ERROR: Core order failed. Entire transaction rolled back.';
        RAISE NOTICE 'SQLSTATE: %, Message: %', SQLSTATE, SQLERRM;
END;
$$;


-- ============================================================================
-- TRANSACTION 6: RETURN REQUEST PROCESSING
-- ============================================================================
-- Business Process: Process a customer's return request — validate the order,
-- create a return record, and conditionally issue a refund based on the
-- return policy (within 30 days, item condition, etc.).
--
-- ACID Properties Demonstrated:
--   Atomicity  — Return request creation, inventory restoration, and refund
--                are bundled. If any step fails, no partial return is recorded.
--   Consistency — Order status transitions are validated (only delivered
--                 orders can be returned). Inventory is correctly restored.
--   Isolation  — Locks prevent duplicate return requests for the same order.
--   Durability — Committed returns are recorded permanently for audit.
-- ============================================================================

DO $$
DECLARE
    v_order_id        INT := 2;
    v_customer_id     INT;
    v_order_status    VARCHAR(50);
    v_order_date      TIMESTAMP;
    v_return_id       INT;
    v_item            RECORD;
    v_refund_amount   NUMERIC(10,2) := 0;
    v_days_since      INT;
BEGIN
    RAISE NOTICE '=== TRANSACTION 6: RETURN REQUEST PROCESSING ===';

    -- Lock and validate the order
    SELECT customer_id, status, order_date
    INTO v_customer_id, v_order_status, v_order_date
    FROM orders
    WHERE order_id = v_order_id
    FOR UPDATE;

    IF v_order_status IS NULL THEN
        RAISE EXCEPTION 'Order % not found', v_order_id;
    END IF;

    -- Only delivered or confirmed orders can be returned
    IF v_order_status NOT IN ('delivered', 'confirmed') THEN
        RAISE EXCEPTION 'Order % cannot be returned (current status: %)', v_order_id, v_order_status;
    END IF;

    -- Check return window (30 days)
    v_days_since := EXTRACT(DAY FROM (NOW() - v_order_date));
    IF v_days_since > 30 THEN
        RAISE EXCEPTION 'Return window expired for order % (% days since purchase)', v_order_id, v_days_since;
    END IF;

    -- Check no existing return request
    IF EXISTS (SELECT 1 FROM return_requests WHERE order_id = v_order_id AND status != 'rejected') THEN
        RAISE EXCEPTION 'A return request already exists for order %', v_order_id;
    END IF;

    RAISE NOTICE 'Order % eligible for return (% days old, status: %)', v_order_id, v_days_since, v_order_status;

    -- Create return request
    INSERT INTO return_requests (order_id, customer_id, reason, status, request_date)
    VALUES (v_order_id, v_customer_id, 'Product not as described', 'approved', NOW())
    RETURNING return_id INTO v_return_id;

    -- Restore inventory and calculate refund
    FOR v_item IN
        SELECT product_id, quantity, subtotal
        FROM order_items
        WHERE order_id = v_order_id
    LOOP
        UPDATE inventory
        SET quantity = quantity + v_item.quantity,
            last_updated = NOW()
        WHERE product_id = v_item.product_id;

        v_refund_amount := v_refund_amount + v_item.subtotal;

        RAISE NOTICE 'Restored % units of product %, refund portion: £%',
            v_item.quantity, v_item.product_id, v_item.subtotal;
    END LOOP;

    -- Issue refund
    UPDATE payments
    SET payment_status = 'refunded'
    WHERE order_id = v_order_id;

    -- Update order status
    UPDATE orders
    SET status = 'returned'
    WHERE order_id = v_order_id;

    RAISE NOTICE '=== RETURN COMPLETE — Return #%, Refund: £% ===', v_return_id, v_refund_amount;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Return processing failed. SQLSTATE: %, Message: %', SQLSTATE, SQLERRM;
END;
$$;
