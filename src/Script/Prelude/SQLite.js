export const querySQLiteTextImpl = async (path, query) => {
  const { Database } = await import("bun:sqlite");
  const database = new Database(path, { readonly: path !== ":memory:", strict: true });

  try {
    const row = database.query(query).get();
    if (row === null) throw new Error("SQLite query returned no row");

    const values = Object.values(row);
    if (values.length !== 1 || typeof values[0] !== "string") {
      throw new Error("SQLite query must return exactly one text column");
    }

    return values[0];
  } finally {
    database.close();
  }
};
