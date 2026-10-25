মুশুলী উচ্চ বিদ্যালয় — Final Website Package

ফাইলগুলো:
- index.html: পুরো ওয়েবসাইটের HTML, CSS ও JavaScript একটি ফাইলে
- assets/: লোগো, প্রতীকী স্কুল ভবনের SVG এবং PWA আইকন
- manifest.webmanifest: PWA অ্যাপের তথ্য
- service-worker.js: cache/offline shell
- schema.sql: Supabase database এবং নিরাপত্তা নীতিমালা

চালু করার নিয়ম:
1) ZIP extract করুন। VS Code-এ mushuli_final ফোল্ডার খুলুন।
2) শুধু index.html double-click করে UI দেখা যাবে, তবে Supabase এবং PWA পুরোপুরি চালাতে localhost/HTTPS ব্যবহার করুন।
3) VS Code-এ Live Server extension থাকলে index.html-এ right-click > Open with Live Server চাপুন।
4) Supabase Dashboard > SQL Editor > New query-তে schema.sql-এর সম্পূর্ণ কোড paste করে Run করুন।
5) Supabase Authentication > Users-এ অফিসিয়াল admin account তৈরি করুন। তার User UID কপি করে schema.sql-এর শেষে থাকা INSERT উদাহরণে YOUR_ADMIN_AUTH_USER_UUID বদলে আলাদাভাবে চালান।
6) index.html-এ SUPABASE_URL ও SUPABASE_PUBLISHABLE_KEY আগে থেকেই দেওয়া আছে। Publishable key ব্রাউজারে ব্যবহারযোগ্য; sb_secret_ বা service_role key কখনো যোগ করবেন না।
7) PWA install করতে HTTPS hosting-এ প্রকাশ করুন (যেমন static hosting) অথবা localhost ব্যবহার করুন। file:// থেকে PWA install হবে না।

Supabase-নির্ভর বৈশিষ্ট্য:
- Public notice, teacher, gallery loading
- Admin sign-in এবং অনুমোদিত admin check
- Notice/teacher/gallery add
- Student result lookup via roll + exam + individual access code
- Admin result insertion through server-side SQL RPC

নিরাপত্তা:
- শুধু Authentication-এ account তৈরি করলেই admin হবে না; UID অবশ্যই public.school_admins-এ থাকতে হবে।
- Supabase secret/service_role key frontend-এ রাখবেন না।
- ফলাফল সংবেদনশীল তথ্য হতে পারে। স্কুলের অনুমতি নিয়ে প্রকাশ করুন এবং প্রত্যেক শিক্ষার্থীকে আলাদা গোপন কোড দিন।
- যোগাযোগ ফর্ম demo; এটি সরাসরি ইমেইল পাঠায় না, বরং বার্তা কপি করে দেয়।
- ভবনের ছবিটি আসল স্কুলের ছবি নয়, একটি প্রতীকী SVG illustration। আসল ছবি থাকলে assets-এ রেখে index.html-এর assets/school-building.svg path বদলান।

তথ্য-উৎস:
বিদ্যালয়ের অবস্থান, প্রতিষ্ঠার বছর (১৯৪১), শ্রেণি ও সংক্ষিপ্ত ইতিহাস ব্যবহারকারীর দেওয়া PDF থেকে নেওয়া। যোগাযোগের নির্দিষ্ট ফোন/ইমেইল নিশ্চিতভাবে দেওয়া ছিল না, তাই বানিয়ে যোগ করা হয়নি।
