import matplotlib.pyplot as plt
import matplotlib.patches as patches

file = open("BAa5c5.ozn", "r") 
vessels = []

for line in file.readlines():
    line=line.rstrip()
    parts=line.split(";")
    vessel_id,location=parts[0].split(":")
    vessel_id=int(vessel_id)

    quay_start, quay_end = map(int, location.split("-"))
    time_start, time_end = map(int, parts[1].split(".."))

    if len(parts[2]) > 0:
        cranes_used = list(map(int, parts[2].split(",")))
    else:
        cranes_used = []

    vessels.append({
        'id': vessel_id,
        'Sq': quay_start,
        'Eq': quay_end,
        'Si': time_start,
        'Ei': time_end if time_end > time_start else time_end+24*7,
        'cranes': cranes_used
    })

# Visualize the vessels on the quay
fig, ax = plt.subplots(figsize=(12, 8))
ax.set_facecolor('lightblue')       # Background color of the plot area
# Total quay length for x-axis (based on the maximum quay position)
L = max(vessel['Eq'] for vessel in vessels)
# Total time for y-axis (based on the maximum time)
T = max(vessel['Ei'] for vessel in vessels)

for vessel in vessels:
    rect = patches.Rectangle(
        (vessel['Sq'], vessel['Si']),
        vessel['Eq'] - vessel['Sq'],
        vessel['Ei'] - vessel['Si'],
        linewidth=1,
        edgecolor='black',
        facecolor='grey',
        alpha=0.5)
    
    ax.add_patch(rect)
    # Add vessel ID and crane info in the middle of the rectangle
    crane_text = f"V{vessel['id']} (Cranes: {','.join(map(str, vessel['cranes']))})"

    ax.text((vessel['Sq'] + vessel['Eq'])/2,
            (vessel['Si'] + vessel['Ei'])/2,
            crane_text, ha='center', va='center', color='black', weight='bold')

# Set the limits and labels
ax.set_xlim(0, L)
ax.set_ylim(0, T)
ax.set_xlabel('Quay Length (meters)')
ax.set_ylabel('Time (hours)')
ax.set_title('Berth Allocation Visualization')

# Show the plot
# plt.gca().invert_yaxis()  # Optional: Invert y-axis if you want time to go from top to bottom
plt.grid(True)
plt.show()