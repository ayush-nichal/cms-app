/*
  Warnings:

  - Added the required column `channel` to the `NotificationLog` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "NotificationLog" ADD COLUMN     "channel" TEXT NOT NULL;
