const request = require("supertest");
const server = require("./index");

describe("App endpoints", () => {

  test("GET / returns 200", async () => {
    const res = await request(server).get("/");
    expect(res.statusCode).toBe(200);
  });

  test("GET /health returns healthy status", async () => {
    const res = await request(server).get("/health");
    expect(res.statusCode).toBe(200);
    expect(JSON.parse(res.text).status).toBe("healthy");
  });

  test("GET /unknown returns 404", async () => {
    const res = await request(server).get("/unknown");
    expect(res.statusCode).toBe(404);
  });

});
