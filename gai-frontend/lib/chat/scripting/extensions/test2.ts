declare const _: any; // Declare Lodash globally as "any"

// Load Lodash from CDN
const cdnUrl = "https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.min.js";
const script = document.createElement('script');
script.src = cdnUrl;
script.onload = () => console.log("Lodash library loaded successfully!");
script.onerror = () => console.error("Failed to load Lodash library.");
document.head.appendChild(script);

// Exercise Lodash after ensuring it's loaded
script.onload = () => {
    if (typeof _ !== 'undefined') {
        console.log("Lodash is available:", _.VERSION); // Log Lodash version

        // Demonstrate Lodash's cloneDeep function
        const original = {a: 1, b: {c: 2}};
        const clone = _.cloneDeep(original);

        console.log("Original object:", original);
        console.log("Cloned object:", clone);
        console.log(
            "Are objects equal but not the same reference?",
            original !== clone && JSON.stringify(original) === JSON.stringify(clone)
        );
    } else {
        console.error("Lodash is not available!");
    }
};
