import { randomUUID } from 'crypto';

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

let db = null;

export function setDatabase(database) {
  db = database;
}

function validateUUID(value, fieldName) {
  if (!value || typeof value !== 'string') {
    throw new Error(`${fieldName} is required and must be a string`);
  }
  if (!UUID_REGEX.test(value)) {
    throw new Error(`${fieldName} must be a valid UUID`);
  }
}

function validateRange(value, fieldName, min, max) {
  if (typeof value !== 'number' || !Number.isInteger(value)) {
    throw new Error(`${fieldName} must be an integer`);
  }
  if (value < min || value > max) {
    throw new Error(`${fieldName} must be between ${min} and ${max}`);
  }
}

export async function createRating(input) {
  if (!db) {
    throw new Error('Database not initialized');
  }

  validateUUID(input.drink_id, 'drink_id');
  validateRange(input.overall_rating, 'overall_rating', 1, 5);
  validateRange(input.sweetness, 'sweetness', 1, 10);
  validateRange(input.boba_texture, 'boba_texture', 1, 10);
  validateRange(input.tea_strength, 'tea_strength', 1, 10);

  const id = randomUUID();
  const now = new Date().toISOString();
  const reviewerName = input.reviewer_name ?? null;
  const reviewText = input.review_text ?? null;

  await db.run(
    `INSERT INTO drink_ratings (
      id, drink_id, reviewer_name, overall_rating,
      sweetness, boba_texture, tea_strength, review_text,
      created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    id,
    input.drink_id,
    reviewerName,
    input.overall_rating,
    input.sweetness,
    input.boba_texture,
    input.tea_strength,
    reviewText,
    now,
    now
  );

  return {
    id,
    drink_id: input.drink_id,
    reviewer_name: reviewerName,
    overall_rating: input.overall_rating,
    sweetness: input.sweetness,
    boba_texture: input.boba_texture,
    tea_strength: input.tea_strength,
    review_text: reviewText,
    created_at: now,
    updated_at: now
  };
}

export async function listRatingsByDrink(drinkId) {
  if (!db) {
    throw new Error('Database not initialized');
  }

  validateUUID(drinkId, 'drink_id');

  const rows = await db.all(
    `SELECT
      id,
      drink_id,
      reviewer_name,
      overall_rating,
      sweetness,
      boba_texture,
      tea_strength,
      review_text,
      created_at,
      updated_at
    FROM drink_ratings
    WHERE drink_id = ?
    ORDER BY created_at DESC`,
    drinkId
  );

  return rows.map(row => ({
    id: row.id,
    drink_id: row.drink_id,
    reviewer_name: row.reviewer_name,
    overall_rating: row.overall_rating,
    sweetness: row.sweetness,
    boba_texture: row.boba_texture,
    tea_strength: row.tea_strength,
    review_text: row.review_text,
    created_at: row.created_at,
    updated_at: row.updated_at
  }));
}

export async function getRatingAggregates(drinkId) {
  if (!db) {
    throw new Error('Database not initialized');
  }

  validateUUID(drinkId, 'drink_id');

  const row = await db.get(
    `SELECT
      COUNT(*) as total_count,
      AVG(overall_rating) as overall_rating,
      AVG(sweetness) as sweetness,
      AVG(boba_texture) as boba_texture,
      AVG(tea_strength) as tea_strength
    FROM drink_ratings
    WHERE drink_id = ?`,
    drinkId
  );

  const totalCount = row.total_count;

  if (totalCount === 0) {
    return {
      overall_rating: null,
      sweetness: null,
      boba_texture: null,
      tea_strength: null,
      total_count: 0
    };
  }

  return {
    overall_rating: row.overall_rating,
    sweetness: row.sweetness,
    boba_texture: row.boba_texture,
    tea_strength: row.tea_strength,
    total_count: totalCount
  };
}
