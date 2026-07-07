-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jul 04, 2026 at 03:00 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.5.5

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `android_app`
--

-- --------------------------------------------------------

--
-- Table structure for table `appointments`
--

CREATE TABLE `appointments` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(120) NOT NULL,
  `appointment_date` date NOT NULL,
  `appointment_time` time NOT NULL,
  `notes` text DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'confirmed',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `appointments`
--

INSERT INTO `appointments` (`id`, `user_id`, `title`, `appointment_date`, `appointment_time`, `notes`, `status`, `created_at`, `updated_at`) VALUES
(1, 1, 'Consultation', '2026-07-04', '10:00:00', 'This is booking time', 'cancelled', '2026-07-03 13:53:29', '2026-07-03 14:00:14'),
(2, 1, 'Consultation', '2026-07-04', '10:00:00', 'Need to speak with the head', 'confirmed', '2026-07-03 14:59:27', '2026-07-03 14:59:27'),
(3, 1, 'Consultation', '2026-07-05', '10:00:00', 'Cancellation', 'confirmed', '2026-07-04 02:58:43', '2026-07-04 02:58:43');

-- --------------------------------------------------------

--
-- Table structure for table `documents`
--

CREATE TABLE `documents` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(120) NOT NULL,
  `document_type` varchar(50) NOT NULL,
  `file_name` varchar(180) NOT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `documents`
--

INSERT INTO `documents` (`id`, `user_id`, `title`, `document_type`, `file_name`, `notes`, `created_at`) VALUES
(1, 1, 'Appointment Receipt', 'Receipt', 'appointment_receipt.pdf', 'Sample receipt for your latest booking.', '2026-07-03 15:06:38'),
(2, 1, 'Monthly Invoice', 'Invoice', 'monthly_invoice.pdf', 'Payment document for account billing.', '2026-07-03 15:06:38'),
(3, 1, 'Profile Form', 'Form', 'profile_update_form.pdf', 'Form for keeping profile details current.', '2026-07-03 15:06:38');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `sender` varchar(120) NOT NULL,
  `subject` varchar(160) NOT NULL,
  `body` text NOT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `user_id`, `sender`, `subject`, `body`, `is_read`, `created_at`) VALUES
(1, 1, 'Support team', 'Welcome to your inbox', 'You can now receive account updates and support replies here.', 1, '2026-07-03 14:18:18'),
(3, 1, 'Billing team', 'Invoice question', 'Your billing messages and payment updates will appear in this inbox.', 1, '2026-07-03 14:18:18');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(500) NOT NULL,
  `email` varchar(500) NOT NULL,
  `phone_number` varchar(50) NOT NULL,
  `address` varchar(100) NOT NULL,
  `password` varchar(200) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `phone_number`, `address`, `password`) VALUES
(1, 'Daniel', 'seongchunlaw050@gmail.com', '01133903509', '309 Blok C5 Wangsa Maju Seksyen 2 53000 Kuala Lumpur', '$2y$12$AKFnRojLNsxL27qoqDq5z.wcEkkGAKP/RyJsCvxPXnGEqa8HOlq/u'),
(2, 'Grabriel Lim', 'javierlim930@gmail.com', '0142342349', '306 Blok C5 Wangsa Maju Seksyen 2 53300 Kuala Lumpur', '$2y$12$V6ZQWpEdzf3EOjrpOQDLneRIkCiw4sPhnVx/fuleH5cRN0dTUp0Xy'),
(3, 'Nick Wong', 'nickwong050@gmail.com', '+60193453458', '404 Blok C5 Wangsa Maju Seksyen 2 53300 Kuala Lumpur', '$2y$12$nURJtQjXI822qrenFdsjr.1.h9JYWbznp4cq7vJaoGpY9NKoGbMFW');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `appointments`
--
ALTER TABLE `appointments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `documents`
--
ALTER TABLE `documents`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `appointments`
--
ALTER TABLE `appointments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `documents`
--
ALTER TABLE `documents`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `appointments`
--
ALTER TABLE `appointments`
  ADD CONSTRAINT `appointments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
