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

----------------------------------
CREATE TABLE user_daily_scores (
    id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id bigint unsigned NOT NULL,
    date DATE NOT NULL,
    reading_time_score INT NOT NULL DEFAULT 0,
    consistency_score INT NOT NULL DEFAULT 0,
    progress_score INT NOT NULL DEFAULT 0,
    engagement_score INT NOT NULL DEFAULT 0,
    total_score INT NOT NULL DEFAULT 0,
    pages_read INT NOT NULL DEFAULT 0,
    reading_minutes INT NOT NULL DEFAULT 0,
    UNIQUE INDEX idx_user_date (user_id, date)
);

----------------------------------
CREATE TABLE user_weekly_scores (
    id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    year INT NOT NULL,
    week INT NOT NULL, -- Week number (1-53)
    total_score INT NOT NULL DEFAULT 0,
    days_active INT NOT NULL DEFAULT 0,
    total_reading_minutes INT NOT NULL DEFAULT 0,
    total_pages_read INT NOT NULL DEFAULT 0,
    UNIQUE INDEX idx_user_week (user_id, year, week)
);

----------------------------------
CREATE TABLE user_reading_progress (
    user_id BIGINT NOT NULL,
    page_number INT NOT NULL,
    surah_name VARCHAR(100) NOT NULL,
    first_read_date DATE,
    read_count INT NOT NULL DEFAULT 0,
    PRIMARY KEY (user_id, page_number)
);

----------------------------------
CREATE TABLE IF NOT EXISTS bookmarks (
    id bigint unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
    page_number INT NOT NULL,
    surah_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- unique page number
    UNIQUE KEY idx_page_number (page_number)
);

