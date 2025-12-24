import { useState } from "react";
import { searchArticles } from "../api";

function SearchPage() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSearch = async (event) => {
    event.preventDefault();
    setLoading(true);
    setError("");
    try {
      // Fetch search results from backend; backend does ILIKE on title/content.
      const data = await searchArticles(query);
      setResults(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="card">
      <h2>Search Articles</h2>
      <form onSubmit={handleSearch} className="form">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Enter keyword"
          required
        />
        <button type="submit" disabled={loading}>
          {loading ? "Searching..." : "Search"}
        </button>
      </form>
      {error && <p className="error">{error}</p>}
      <ul className="list">
        {results.map((item) => (
          <li key={item.id} className="list__item">
            <div className="list__meta">
              <strong>{item.title}</strong>
              <small>{new Date(item.created_at).toLocaleString()}</small>
            </div>
            <p>{item.content}</p>
          </li>
        ))}
      </ul>
    </section>
  );
}

export default SearchPage;

