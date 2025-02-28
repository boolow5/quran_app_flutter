CREATE TABLE IF NOT EXISTS users (
  id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  uid varchar(100) NOT NULL,
  email varchar(100) NOT NULL,
  name varchar(100) NOT NULL,
  timezone VARCHAR(50) DEFAULT 'UTC',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY idx_uid (uid)
);

----------------------------------
CREATE TABLE IF NOT EXISTS reading_events (
    id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id bigint unsigned NOT NULL,
    page_number INT NOT NULL,
    surah_name VARCHAR(100) NOT NULL,
    seconds_open INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_created (user_id, created_at)
);

----------------------------------
CREATE TABLE IF NOT EXISTS daily_summaries (
    id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id bigint unsigned NOT NULL,
    date DATE NOT NULL,
    total_seconds INT NOT NULL DEFAULT 0,
    threshold_met tinyint NOT NULL DEFAULT 0,
    UNIQUE KEY idx_user_date (user_id, date)
);

----------------------------------
CREATE TABLE IF NOT EXISTS user_streaks (
    user_id INT UNSIGNED PRIMARY KEY PRIMARY KEY,
    current_streak INT NOT NULL DEFAULT 0,
    longest_streak INT NOT NULL DEFAULT 0,
    last_active_date DATE
);

----------------------------------
CREATE TABLE IF NOT EXISTS user_devices (
    id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
    uid VARCHAR(255) NOT NULL,
    user_id bigint unsigned NOT NULL,
    device_token VARCHAR(255) NOT NULL,
    -- add index for user_id and uid
    INDEX idx_user_id_uid (user_id, uid)
);
