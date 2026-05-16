/**
 * Helper to get currently logged-in admin data from localStorage
 */
export const getAdminData = () => {
    if (typeof window === "undefined") return null;
    
    try {
        const data = localStorage.getItem("adminData");
        return data ? JSON.parse(data) : null;
    } catch (error) {
        console.error("Error parsing admin data:", error);
        return null;
    }
};

/**
 * Get only the location of the logged-in admin
 * Used for filtering queries in service layer
 */
export const getAdminLocation = () => {
    const admin = getAdminData();
    return admin?.lokasi || null;
};
