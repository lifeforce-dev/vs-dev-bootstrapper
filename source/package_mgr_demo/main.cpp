#include <nlohmann/json.hpp>
#include <asio.hpp>
#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <fstream>
#include <chrono>
#include <iostream>


// This file is basically just a build test to make sure everything is still hooked up properly.

int main() {
	// Setup multi-sink logger
	auto console_sink = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
	auto file_sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>("logs.txt", true);
	spdlog::logger logger("multi_sink", { console_sink, file_sink });
	logger.set_level(spdlog::level::debug); // Set global log level to debug
	logger.flush_on(spdlog::level::debug);  // Flush to the sinks on each log

	// Log message to console and file
	logger.info("Starting application");

	glm::vec3 vec(1.0f, 0.0f, 0.0f); // A simple vector pointing along the X axis
	glm::mat4 trans = glm::rotate(glm::mat4(1.0f), glm::radians(90.0f), glm::vec3(0.0f, 0.0f, 1.0f)); // Rotate 90 degrees around the Z axis
	glm::vec3 transformedVec = trans * glm::vec4(vec, 1.0f);

	// Log the transformed vector
	logger.info("Original vector: [{}, {}, {}]", vec.x, vec.y, vec.z);
	logger.info("Transformed vector: [{}, {}, {}]", transformedVec.x, transformedVec.y, transformedVec.z);

	// Create and write JSON to file
	nlohmann::json jsonExample;
	jsonExample["name"] = "John Doe";
	jsonExample["age"] = 30;
	jsonExample["occupation"] = "Software Developer";
	jsonExample["languages"] = { "C++", "Python", "JavaScript" };

	std::ofstream jsonFile("example.json");
	if (jsonFile.is_open()) {
		jsonFile << jsonExample.dump(4);
		jsonFile.close();
		logger.info("JSON file written successfully");
	}
	else {
		logger.error("Failed to write JSON file.");
	}

	// Read JSON from file
	std::ifstream jsonFileRead("example.json");
	if (jsonFileRead.is_open()) {
		nlohmann::json jsonRead;
		jsonFileRead >> jsonRead;
		jsonFileRead.close();

		// Log the contents of the JSON object
		logger.info("JSON file read successfully: {}", jsonRead.dump(4));
	}
	else {
		logger.error("Could not open JSON file for reading.");
	}

	// ASIO Example: Setting up a timer
	asio::io_context io_context;

	// Setting a timer for 5 seconds
	asio::steady_timer timer(io_context, std::chrono::seconds(5));
	timer.async_wait([&logger](const std::error_code& /*e*/) {
		logger.info("Timer expired!");
		});

	logger.info("Starting ASIO timer for 5 seconds...");

	// Run the ASIO context to work with the timer
	io_context.run();

	return 0;
}