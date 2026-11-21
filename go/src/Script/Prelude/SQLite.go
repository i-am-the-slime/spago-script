package ffi

import (
	"database/sql"
	"errors"
	"net/url"

	"github.com/i-am-the-slime/iris-go/aff"
	_ "modernc.org/sqlite"
)

// QuerySQLiteTextImpl queries on a goroutine of its own and hands the text, or the reason there is
// none, to finished on the event loop.
func QuerySQLiteTextImpl[R any](failed func(string) R, found func(string) R, path string, query string, finished func(R)) {
	retire := aff.Hold()
	go func() {
		text, err := queryText(path, query)
		aff.Exclusive(func() {
			if err != nil {
				finished(failed(err.Error()))
			} else {
				finished(found(text))
			}
		})
		retire()
	}()
}

func queryText(path string, query string) (string, error) {
	database, err := sql.Open("sqlite", source(path))
	if err != nil {
		return "", err
	}
	defer database.Close()
	rows, err := database.Query(query)
	if err != nil {
		return "", err
	}
	defer rows.Close()
	columns, err := rows.Columns()
	if err != nil {
		return "", err
	}
	if !rows.Next() {
		if err := rows.Err(); err != nil {
			return "", err
		}
		return "", errors.New("SQLite query returned no row")
	}
	if len(columns) != 1 {
		return "", errors.New("SQLite query must return exactly one text column")
	}
	var value any
	if err := rows.Scan(&value); err != nil {
		return "", err
	}
	switch text := value.(type) {
	case string:
		return text, nil
	case []byte:
		return string(text), nil
	default:
		return "", errors.New("SQLite query must return exactly one text column")
	}
}

// source opens a file read-only, as bun:sqlite's readonly option does, and :memory: read-write.
func source(path string) string {
	if path == ":memory:" {
		return path
	}
	return "file:" + (&url.URL{Path: path}).EscapedPath() + "?mode=ro"
}
